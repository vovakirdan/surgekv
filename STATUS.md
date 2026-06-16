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

## Known Limitations

The current server is intentionally small:

- one in-process sharded store
- one listener process
- accepted connections beyond `--max-clients` wait in the OS backlog until a slot frees; the server does not yet send an immediate protocol-level rejection
- completed client task handles are retained by their dispatcher until server shutdown
- current local network benchmark numbers are dominated by Surge runtime/stdlib networking overhead, especially the multi-worker network poll path
- disconnect cleanup still scans the affected shard stores instead of using a reverse client-to-key index
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

There is no current compiler blocker for the implemented spawn-per-connection server slice.

## Recommended Next Work

The most reasonable next steps for `surgekv` are:

1. add broader multi-client runtime tests for cross-shard disconnect and aggregate metadata
2. add a reverse client-to-key index if disconnect cleanup becomes too costly
3. expand pattern support beyond simple `*` matching only if it is still worth the complexity
