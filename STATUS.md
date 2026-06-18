# surgekv Status

This document tracks the current working scope of `surgekv`.
It should describe what is already usable today, what is still missing, and which upstream Surge bugs are currently shaping implementation choices.

## Current Slice

`surgekv` is now a minimal working TCP server written in Surge.

Implemented pieces:

- `proto/`: line-oriented wire protocol parsing and response formatting
- `state/`: in-memory key/value engine with ownership-aware semantics
- `config/`: CLI configuration parser powered by the `sigil` module
- `manager/`: state-manager actor task that owns the store and processes command messages
- `expiry/`: background expiry task that periodically asks the state manager to prune expired leases
- `server/`: TCP listener plus accepted-client dispatchers that spawn one client task per connection
- `main.sg`: thin `@entrypoint("argv")` bootstrap

## Implemented Commands

The following commands are implemented and usable:

- `PING`
  Health check. Returns `PONG` and is useful to verify that the server is reachable and the TCP session is alive.
- `WHOAMI`
  Returns the server-assigned client id together with the current number of owned and borrowed keys for that connection.
- `NEW <key> <json>`
  Creates a new key with the provided JSON value. Fails with `EXISTS` if the key already exists.
- `GET <key>`
  Reads the current value of a key. Returns `VALUE <json>` if the key exists, otherwise `NOT_FOUND`.
- `SET <key> <json>`
  Updates the value of an existing key. Works only when the key is free or owned by the current client.
- `SET <key> <json> IF <version>`
  Conditional update with optimistic concurrency. The write succeeds only if the current entry version matches the provided version.
- `DEL <key>`
  Deletes a key. Works only when the key is free or owned by the current client.
- `OWN <key> [TTL <seconds>]`
  Acquires an exclusive write lease for a key. While the key is owned, other clients cannot write or acquire ownership.
- `BORROW <key> [TTL <seconds>]`
  Registers the current client as a borrower of the key. This is the shared read side of the ownership model.
- `RELEASE <key>`
  Releases ownership or a borrow held by the current client. This is how clients explicitly drop a lease before disconnecting.
- `SEAL <key>`
  Makes a key permanently immutable. After sealing, no further writes are allowed.
- `STAT <key>`
  Returns metadata for a key: owner presence, borrower count, stored TTL, current version, and sealed flag.
- `KEYS [pattern]`
  Lists known keys. Without a pattern it returns the full key set; with a pattern it filters keys using simple `*` glob matching and returns a deterministic sorted list.

Special handling:

- `Disconnect` exists as an internal command and is triggered when a client connection closes. It clears ownership and borrow state associated with that client.

## Implemented Semantics

The current engine already enforces the core ownership model:

- owned keys block writes from other clients
- borrowed keys are tracked per client
- sealing makes a key immutable
- conditional writes use `version`
- disconnect cleanup releases ownership and borrowed state for that client
- lease TTL values are stored, returned in responses, and expired by a background worker
- command handling also keeps a lazy expiry pass as a safety net before applying each command
- TTL deadlines use monotonic millisecond timestamps stored as `int64`
- each shard keeps an expiry index of lease deadlines, so expiry no longer scans every stored key
- each `Store` shard is owned by its state-manager task instead of being mutated directly by the TCP loop
- key-scoped commands are routed to deterministic state-manager shards with `stdlib/hash`
- `WHOAMI`, `KEYS`, `Disconnect`, and expiry ticks aggregate or broadcast across shards
- accepted TCP clients are dispatched into dedicated client tasks, so one idle connection does not block other clients even with `--workers 1`
- disconnect auto-release is queued through a cleanup worker, so socket tasks close and finish without waiting for every shard cleanup reply
- `--max-clients` caps accepted active clients when set above zero; `0` keeps the server unlimited
- the expiry worker sends best-effort prune requests through the same manager queue, so it cannot mutate state concurrently with commands

## How To Run

Start the server:

```bash
cd surgekv
surge run . -- --port 7400 --shards 4
```

Connect from another terminal:

```bash
nc 127.0.0.1 7400
```

Example session:

```text
PING
NEW k 1
GET k
OWN k TTL 30
WHOAMI
KEYS k*
```

Expected responses:

```text
PONG
OK version=1
VALUE 1
OK ttl=30
CLIENT id=client-1 owned=1 borrowed=0
LIST
k
END
```

## Verification

The current slice has been checked with:

```bash
cd surgekv
surge fmt --check .
surge diag .
surge diag --directives=run .
surge build .
```

The server should also be smoke-tested end-to-end in an environment that permits loopback TCP listeners:

- `surge run . -- --port <port> --shards 4`
- `./target/debug/surgekv --port <port> --shards 4`
- `./scripts/concurrency_smoke.sh [port]` (runs the multi-client path with `--workers 1`)
- `./scripts/max_clients_smoke.sh [port]` (verifies `--max-clients 1` slot gating)
- `./scripts/bench.sh` (writes a short local throughput/latency report)

## Current Benchmark Snapshot

Checked locally on 2026-06-18 with Surge `7f084eed392c`.

The old uniform single-client latency bug no longer reproduces, and the
disconnect fanout stall no longer reproduces in the full local matrix.

Current local 32-client stateful results use 5000 requests per row, 100 keys,
and 64-byte JSON values:

- default `SURGE_THREADS`: `GET 4034 rps`, `SET 3717 rps`, `mixed 3459 rps`,
  zero errors
- `SURGE_THREADS=1`: `GET 2282 rps`, `SET 1329 rps`, `mixed 1746 rps`, zero
  errors
- `SURGE_THREADS=8`: `GET 5299 rps`, `SET 4728 rps`, `mixed 4790 rps`, zero
  errors
- Redis and Valkey on the same host complete the same rows around `60-72k rps`
  with p50 latencies around `168-227us`
- clean LLVM output now calls `rt_net_read_bytes`/`rt_net_write_bytes`; server
  `strace` shows bulk socket calls such as `read(fd, "PING\n", 1024)` and
  `write(fd, "PONG\n", 5)`

Reports:

- `benchmarks/latest-local.md`: default `SURGE_THREADS`
- `benchmarks/latest-local-threads1.md`: `SURGE_THREADS=1`
- `benchmarks/latest-local-threads8.md`: `SURGE_THREADS=8`

## Known Limitations

The current server is intentionally small:

- one in-process sharded store
- one listener process
- accepted connections beyond `--max-clients` wait in the OS backlog until a slot frees; the server does not yet send an immediate protocol-level rejection
- completed client task handles are retained by their dispatcher until server shutdown
- current local benchmark numbers are still dominated by Surge runtime/server overhead versus Redis/Valkey, especially multi-client tail latency
- disconnect cleanup is off the socket hot path, but still scans the affected shard stores instead of using a reverse client-to-key index
- the expiry index uses lazy stale-record cleanup rather than a heap or delete-aware priority queue
- no authentication
- no persistence
- `KEYS` currently supports `*` glob matching only

## Upstream Surge Issues

The previously blocking Surge issues are closed in the current compiler:

- `#72`: `@entrypoint("argv")` default parameter build failure
- `#73`: borrowed `TcpConn` through async helper VM crash
- `#74`: `Map.get_mut(...)` mutable-ref VM move panic
- `#80`: array field access through `&mut` struct backend failures
- `#82`: `stdlib/time.Duration` conversion intrinsic lowering

The runtime/network issues from the benchmark investigation are closed upstream
and the current local binary verifies the two latest fixes:

| Issue | Local status |
| --- | --- |
| `#102` runtime waiter delay | Fixed for the old single-client 50 ms symptom. |
| `#103` byte-wise stdlib I/O | Fixed in the current path; superseded by the later `#111` verification. |
| `#104` `TCP_NODELAY` | Verified with `strace`; sockets set `TCP_NODELAY`. |
| `#105` `SURGE_THREADS=1` panic | Fixed; `SURGE_THREADS=1` now passes smoke and benchmark runs. |
| `#110` channel fanout stall | Fixed; default full matrix and targeted churn runs complete with zero errors. |
| `#111` bulk net lowering | Fixed; clean IR and server `strace` show byte-array network calls. |

There is no current compiler blocker for the implemented spawn-per-connection
server slice. Performance work is now a profiling problem, not a known compiler
correctness blocker.

## Recommended Next Work

The core protocol works. The next work should stay focused on measured
throughput, latency tails, and resource use:

1. isolate the remaining manager-channel hop cost with PING-only and state-path
   microbenchmarks before changing server architecture
2. add server health probes and per-row process isolation to the benchmark
   harness so one wedged row cannot hide later command behavior
3. extend the benchmark harness with RSS/heap sampling and a longer soak mode
4. add idle-client scaling runs to validate `--max-clients` behavior and
   completed-task retention under churn
5. add targeted load scenarios for hot-key ownership contention, disconnect
   churn, and TTL churn
6. add a reverse client-to-key index if disconnect cleanup becomes too costly
7. expand pattern support beyond simple `*` matching only if product usage needs it
