# surgekv — Design Document

> **Ownership-aware key-value store written in Surge.**
> A proof of concept: what if the KV protocol itself expressed ownership semantics?

---

## 1. Concept

Standard KV stores (Redis, Memcached) treat every key as a shared mutable resource. Race conditions are the caller's problem. Locks are advisory at best.

surgekv embeds Surge's ownership model directly into the wire protocol:

- A client that **OWNs** a key has an exclusive write lease — no one else can write or acquire it.
- Clients that **BORROW** a key share a read-only view — many readers, no writers.
- A **SEALed** key becomes permanently immutable — no owner, no writers, ever.
- When a client disconnects, all its owned and borrowed keys are **automatically released** — no orphaned locks.

The result is a store where the protocol itself prevents races, without any mutex visible to the user.

---

## 2. Data Model

Every key maps to a single `Entry`:

```
Entry {
    value:          string,            // JSON, stored as raw string
    owner:          Option<ClientID>,  // exclusive write holder
    borrowers:      Set<ClientID>,     // shared read-lock holders
    sealed:         bool,              // permanently immutable
    lease_expires:  Option<Instant>,   // auto-release deadline
    version:        uint64,            // monotonic write counter, starts at 1
}
```

A key with no owner, no borrowers, and not sealed is called **free**.
Free keys accept writes from anyone and support optimistic concurrency via `IF version=N`.

---

## 3. Ownership States

A key is always in exactly one of five states:

```
Free ──OWN──► Owned
     ◄─RELEASE─

Free ──BORROW──► Borrowed      (multiple clients can join)
     ◄─RELEASE──

Owned ──SEAL──► Sealed         (permanent, no release)

Free ──SEAL──► error: need OWN first
```

State transitions are atomic inside the State Manager task.

---

## 4. Access Matrix

| Operation | Free | Owned (you) | Owned (other) | Borrowed | Sealed |
|-----------|------|-------------|---------------|----------|--------|
| GET | ✓ | ✓ | ✓ | ✓ | ✓ |
| SET | ✓ | ✓ | `LOCKED` | `LOCKED` | `SEALED` |
| SET ... IF version=N | ✓ | ✓ | `LOCKED` | `LOCKED` | `SEALED` |
| DEL | ✓ | ✓ | `LOCKED` | `LOCKED` | `SEALED` |
| OWN | ✓ | ✓ (renew TTL) | `CONFLICT` | `CONFLICT` | `SEALED` |
| BORROW | ✓ | `OWNED` | `OWNED` | ✓ (join) | ✓ |
| RELEASE | — | ✓ | — | ✓ | — |
| SEAL | need OWN | ✓ | — | — | — |

---

## 5. Protocol

### 5.1 Transport

Plain TCP, port **7379** by default.
Text-based, line-oriented (`\n` terminated).
Each request is a single line. JSON values must not contain literal newlines (escape as `\n`).
No authentication in v1.

### 5.2 Commands

```
PING
WHOAMI

NEW  <key> <json>
GET  <key>
SET  <key> <json>
SET  <key> <json> IF <version>
DEL  <key>

OWN     <key> [TTL <seconds>]
BORROW  <key> [TTL <seconds>]
RELEASE <key>
SEAL    <key>

STAT    <key>
KEYS    [<glob>]
```

### 5.3 Responses

```
PONG
OK [version=N] [ttl=N]
VALUE <json>
CLIENT id=<uuid> owned=N borrowed=N
STAT owner=<id>|none borrowers=N ttl=N|none version=N sealed=<true|false>
LIST
<key>
<key>
END
ERROR <CODE> <human message>
```

### 5.4 Error Codes

| Code | Meaning |
|------|---------|
| `CONFLICT` | OWN attempted on already-owned key |
| `LOCKED` | SET/DEL attempted on owned or borrowed key |
| `SEALED` | Operation refused on a sealed key |
| `NOT_FOUND` | Key does not exist |
| `EXISTS` | NEW attempted on an existing key |
| `NOT_HOLDER` | RELEASE/SEAL attempted by non-holder |
| `VERSION` | CAS mismatch (`SET ... IF version=N`) |
| `INVALID_JSON` | Value is not valid JSON |
| `BAD_CMD` | Unknown or malformed command |

### 5.5 Example Session

```
# Client A                        # Client B
─────────────────────────────────────────────────────────────────
→ NEW session:42 {"user":"alice"}
← OK version=1

→ OWN session:42 TTL 30
← OK ttl=30

→ SET session:42 {"user":"alice","logged":true}
← OK version=2

                                  → GET session:42
                                  ← VALUE {"user":"alice","logged":true}

                                  → OWN session:42
                                  ← ERROR CONFLICT key is owned by another client

→ RELEASE session:42
← OK

                                  → OWN session:42 TTL 10
                                  ← OK ttl=10

# Client A disconnects — nothing changes, B holds the key
# Client B disconnects — session:42 auto-RELEASE
```

### 5.6 Optimistic Concurrency (free keys)

```
→ GET counter
← VALUE 41  (version=5 embedded in STAT)

→ STAT counter
← STAT owner=none borrowers=0 ttl=none version=5 sealed=false

→ SET counter 42 IF 5
← OK version=6

→ SET counter 99 IF 5    # another client raced
← ERROR VERSION version mismatch: expected 5, got 6
```

---

## 6. Performance Model

### 6.1 Amortised locking

Under `OWN`, the cost of acquiring the lease is paid once. All subsequent `SET` operations inside the ownership window require no additional coordination — the State Manager already knows who owns the key.

```
OWN key TTL 60   ← one coordination round-trip
SET key ...      ← zero overhead, O(1) map lookup
SET key ...      ← zero overhead
...N times...
RELEASE key      ← one round-trip
```

The longer the ownership window, the better the amortised throughput per operation.

### 6.2 Sharding (horizontal scale)

A single State Manager is a sequential bottleneck. surgekv runs N State Manager tasks in parallel, each owning a disjoint slice of the keyspace:

```
shard_index = hash(key) % num_shards
```

Each shard is an independent Surge task with exclusive ownership of its HashMap — no mutexes, no shared memory. Operations on different keys in different shards execute fully in parallel.

Number of shards is set at startup: `surgekv --shards 8` (default: `8` until the stdlib exposes host CPU count).

### 6.3 Borrowed reads

Multiple clients holding `BORROW` on the same key read concurrently with no serialisation. The State Manager only serialises ownership transitions (`OWN`/`RELEASE`/`SEAL`), not reads.

### 6.4 CAS for uncontended free keys

`SET key value IF version=N` allows optimistic writes without any lock. The State Manager performs the version check atomically. On conflict, the caller retries with the new version. This is sufficient for low-contention counters and configuration keys.

### 6.5 Complexity summary

| Scenario | Mechanism | Parallelism |
|----------|-----------|-------------|
| Owned key, many SETs | OWN once, then free path | Full — single writer guaranteed |
| Borrowed key, many GETs | Shared read — no serialisation | Full — N readers |
| Free key, low contention | CAS (`IF version=N`) | Optimistic — no lock |
| Different keys | Sharding | N-fold — independent shards |
| Same key, write contention | One State Manager serialises | Sequential per key — by design |

---

## 7. Architecture

For the current implementation details, see [ARCHITECTURE.md](ARCHITECTURE.md).
This README section is the high-level design overview.

### 7.1 Task layout

```
TCP Listener task
  └─ accept() → spawn Client task per connection

Client task (one per TCP connection)
  ├─ reads lines from socket
  ├─ parses Command
  ├─ routes ClientMsg to correct State Manager via hash(key)
  └─ writes Response line to socket

State Manager task (one per shard)
  ├─ receives ClientMsg from Channel<ClientMsg>
  ├─ owns HashMap<string, Entry> — no other task touches it
  ├─ owns an expiry index for active lease deadlines
  ├─ executes command, updates state
  └─ sends Response to client's reply Channel<string>

Expiry Worker task
  ├─ ticks every 1 second
  ├─ sends Tick message to all State Managers
  └─ each Manager walks its expiry index and auto-releases expired leases
```

### 7.2 Surge types

```surge
// Entry stored per key
type Entry = {
    value:         string,
    owner:         string?,          // ClientID or nothing
    borrowers:     string[],         // list of ClientIDs
    sealed:        bool,
    lease_ttl:     uint?,            // original TTL seconds, or nothing
    lease_deadline_ms: int64?,       // monotonic deadline, or nothing
    version:       uint,
}

type ExpiryRecord = {
    key:         string,
    deadline_ms: int64,
}

// All possible client commands
tag Command {
    Ping,
    WhoAmI,
    New(string, string),             // key, json
    Get(string),
    Set(string, string),             // key, json
    SetIf(string, string, uint),     // key, json, expected_version
    Del(string),
    Own(string, uint?),              // key, ttl_secs?
    Borrow(string, uint?),
    Release(string),
    Seal(string),
    Stat(string),
    Keys(string?),                   // glob pattern or nothing
    Disconnect,                      // client dropped connection
}

// Message routed from Client task to State Manager
type ClientMsg = {
    client_id: string,
    command:   Command,
    reply:     Channel<string>,      // text line back to TCP writer
}
```

### 7.3 Disconnect handling

When a Client task detects EOF or a TCP error, it sends `Command::Disconnect` with its `client_id` to all State Managers (broadcast). Each Manager removes the client from the `owner` and `borrowers` fields of every affected Entry.

This is a full scan of the shard — acceptable for v1 (shards are small). v2 can maintain a reverse index `ClientID → []key` to make it O(affected keys).

### 7.4 Expiry index

Each State Manager owns an `ExpiryRecord[]` alongside its entries map. `OWN` and
`BORROW` with `TTL` append a deadline record. Expiry ticks walk this index
instead of scanning every stored key. Renewed or released leases leave stale
records behind; the next expiry pass drops stale records when their stored
deadline no longer matches the entry's current `lease_deadline_ms`.

---

## 8. Project Structure

```
surgekv/
├── main.sg          # Entrypoint: parse flags and start the server
├── config/          # CLI parsing and ServerConfig defaults
├── proto/           # Wire command parser and response formatting
├── state/           # Entry state, ownership rules, writes, reads, expiry index
├── manager/         # State-manager actor task and request messages
├── server/          # TCP accept loop, client tasks, routing, line I/O
├── expiry/          # Periodic lease-expiry worker
├── deps/sigil/      # Local CLI parsing dependency
├── scripts/         # Smoke tests and benchmark harness
└── benchmarks/      # Local benchmark notes and reports
```

The implementation is no longer a scaffold. The current split keeps protocol,
state, actor management, and TCP serving separate so each layer can be tested or
benchmarked independently.

---

## 9. v1 Scope

### In scope
- All commands listed in §5.2
- Sharding (configurable, default = 8)
- TTL + auto-expiry
- Auto-release on client disconnect
- JSON validation on `NEW`/`SET`
- `KEYS` with glob pattern (`user:*`)
- CAS via `SET ... IF version=N`

### Out of scope (v2+)
- Persistence (AOF log or snapshots)
- Authentication / TLS
- Pub/Sub (`WATCH key` / `NOTIFY`)
- Replication / clustering
- Binary protocol variant
- Reverse index for fast disconnect cleanup

---

## 10. Configuration

Current implementation:

```
surgekv [port] [options]

-p, --port N                 TCP port to listen on (default: 7379)
-w, --workers N              accepted-client dispatcher count (default: 8)
    --shards N               state manager shard count (default: 8)
    --max-clients N          accepted client limit, 0 = unlimited (default: 0)
    --read-cap N             socket read buffer size in bytes (default: 1024)
    --state-queue N          state manager queue capacity (default: 64)
    --client-queue N         accepted client queue capacity (default: 64)
    --expiry-interval-ms N   expiry tick interval in milliseconds (default: 1000)
```

`surgekv 7400` remains supported as shorthand for `surgekv --port 7400`.

The default shard count is currently fixed at `8` because the Surge stdlib does
not expose host CPU count yet.

---

## 11. Benchmarks

Run the local benchmark harness:

```bash
./scripts/bench.sh
```

The script builds `surgekv`, starts an isolated local server, runs a short
`PING`/`GET`/`SET`/`mixed` matrix, and writes
`benchmarks/latest-local.md`.

Redis and Valkey are included automatically when `redis-server` or
`valkey-server` are installed on the same host.

Longer run example:

```bash
SURGEKV_BENCH_REQUESTS=50000 \
SURGEKV_BENCH_CLIENTS="1 8 32 128" \
./scripts/bench.sh
```

Current local numbers are strongly shaped by Surge runtime/server overhead, so
treat the benchmark as a regression and bottleneck finder until the remaining
latency tails are understood.

Current snapshot from 2026-06-18 with Surge `7f084eed392c`:

- default mode completes the 32-client `GET`/`SET`/`mixed` stateful rows with
  zero errors at roughly `3.4-4.0k rps`
- `SURGE_THREADS=1` also completes with zero errors, but is slower for this
  stateful workload at roughly `1.3-2.3k rps`
- `SURGE_THREADS=8` is the best local mode so far at roughly `4.7-5.3k rps`
- Redis and Valkey on the same host complete the same rows around `60-72k rps`
  with much lower latency
- clean LLVM output now calls `rt_net_read_bytes`/`rt_net_write_bytes`, and
  server `strace` shows bulk socket reads and writes

See `benchmarks/latest-local.md`, `benchmarks/latest-local-threads1.md`, and
`benchmarks/latest-local-threads8.md` for the current reports.

---

## 12. Why This Is Interesting

surgekv is not a production Redis replacement. It is a demonstration that:

1. **Protocol semantics can encode memory safety.** The same rules Surge enforces at compile time — exclusive ownership, shared borrows, immutability — can be expressed as a network protocol. Clients that follow the protocol get the same guarantees across the wire that Surge programmers get at compile time.

2. **Actor model = no mutexes.** Each State Manager task owns its HashMap. Surge's ownership system makes this natural — the HashMap simply cannot be accessed from any other task. This is a structural guarantee, not a convention.

3. **Performance improves with longer ownership windows.** Unlike pessimistic locking (where holding a lock always costs), `OWN` amortises the coordination cost over the entire lease. The protocol incentivises good access patterns.

4. **CAS on free keys covers the common case.** Most real workloads have low write contention on individual keys. `IF version=N` handles this without any lock, making `OWN`/`BORROW` an opt-in escalation for the cases that genuinely need it.

The combination of these properties makes surgekv a natural fit for use cases like: distributed session management, feature flag distribution, leader election, configuration versioning, and rate-limit counters — all with first-class concurrency semantics baked into the protocol.
