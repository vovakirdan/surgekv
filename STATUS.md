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
- `WHOAMI`
- `NEW <key> <json>`
- `GET <key>`
- `SET <key> <json>`
- `SET <key> <json> IF <version>`
- `DEL <key>`
- `OWN <key> [TTL <seconds>]`
- `BORROW <key> [TTL <seconds>]`
- `RELEASE <key>`
- `SEAL <key>`
- `STAT <key>`

Special handling:

- `Disconnect` exists as an internal command and is triggered when a client connection closes.
- `KEYS` is parsed but not implemented yet; the current state layer returns `BAD_CMD`.

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
```

Expected responses:

```text
PONG
OK version=1
VALUE 1
OK ttl=30
CLIENT id=client-1 owned=1 borrowed=0
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
- no `KEYS` implementation

## Upstream Surge Issues

The current implementation had to work around several language/runtime bugs:

- `@entrypoint("argv")` with a default argument passes sema but fails during `build`
- borrowed `TcpConn` values routed through async helpers can crash the VM and native binary
- some accepted patterns around mutable refs from `Map.get_mut(...)` can still fail at runtime with move-related VM panics

These are tracked as upstream issues in the main Surge repository and should be removed from this section once fixed.

## Recommended Next Work

The most reasonable next steps for `surgekv` are:

1. commit the current transport slice
2. keep the current server sequential until the upstream issues are fixed or clearly understood
3. implement `KEYS`
4. add TTL expiration
5. move to shard/state-manager task architecture
