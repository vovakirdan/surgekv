# surgekv Status

This document tracks the current working scope of `surgekv`.
It should describe what is already usable today, what is still missing, and which upstream Surge bugs are currently shaping implementation choices.

## Current Slice

`surgekv` is now a minimal working TCP server written in Surge.

Implemented pieces:

- `proto/`: line-oriented wire protocol parsing and response formatting
- `state/`: in-memory key/value engine with ownership-aware semantics
- `server/`: sequential TCP listener and per-connection command loop
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
- lease TTL values are stored, returned in responses, and lazily expired on later commands
- TTL deadlines use monotonic millisecond timestamps stored as `int64`

## How To Run

Start the server:

```bash
cd surgekv
surge run . -- 7400
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

- `surge run . -- <port>`
- `./target/debug/surgekv <port>`

## Known Limitations

The current server is intentionally small:

- one in-process store
- one listener
- sequential connection handling
- no shard manager tasks yet
- no expiry worker yet
- TTL expiration is currently lazy, not background-driven
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

There is no current compiler blocker for the implemented sequential server slice.

## Recommended Next Work

The most reasonable next steps for `surgekv` are:

1. move lazy TTL expiration to a real expiry worker
2. move to shard/state-manager task architecture
3. introduce listener/client/state-manager task separation
4. expand pattern support beyond simple `*` matching only if it is still worth the complexity
