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
- lease TTL values are stored and returned in responses

## How To Run

Start the server:

```bash
cd surgekv
go run ../cmd/surge run . -- 7400
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
go run ../cmd/surge fmt .
go run ../cmd/surge diag .
go run ../cmd/surge build .
```

It has also been smoke-tested end-to-end on both backends:

- `go run ../cmd/surge run . -- <port>`
- `./target/debug/surgekv <port>`

## Known Limitations

The current server is intentionally small:

- one in-process store
- one listener
- sequential connection handling
- no shard manager tasks yet
- no expiry worker yet
- no real TTL expiration yet
- no authentication
- no persistence
- `KEYS` currently supports `*` glob matching only

## Upstream Surge Issues

The current implementation had to work around several language/runtime bugs:

- `@entrypoint("argv")` with a default argument passes sema but fails during `build`
- borrowed `TcpConn` values routed through async helpers can crash the VM and native binary
- some accepted patterns around mutable refs from `Map.get_mut(...)` can still fail at runtime with move-related VM panics

These are tracked as upstream issues in the main Surge repository and should be removed from this section once fixed.

## Recommended Next Work

The most reasonable next steps for `surgekv` are:

1. keep the current server sequential until the upstream issues are fixed or clearly understood
2. add TTL expiration
3. move to shard/state-manager task architecture
4. introduce listener/client/state-manager task separation once the runtime path is stable
5. expand pattern support beyond simple `*` matching only if it is still worth the complexity
