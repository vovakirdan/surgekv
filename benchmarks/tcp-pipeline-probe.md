# surgekv TCP pipeline probe

Generated: 2026-06-22 with Surge `0.1.12-dev` commit `e7142f04`.

Source reports:

- `benchmarks/research-pipeline-threads1.md`
- `benchmarks/research-pipeline-threads8.md`
- `benchmarks/research-batchwrite-threads1.md`
- `benchmarks/research-batchwrite-threads8.md`

## What changed

`scripts/bench_load.go` now accepts operation names with the `_pipe` suffix,
for example `ping_pipe` and `set_pipe`.

Pipeline rows keep the same persistent connection model, but each worker writes
its whole request batch, flushes once, then reads all replies. The latency
columns are amortized per-request batch time, not independent per-command tail
latency.

## Results

32-client rows:

| mode | op | normal rps | pipeline rps | pipeline gain |
| --- | --- | ---: | ---: | ---: |
| `SURGE_THREADS=1` | PING | 29505 | 38358 | 1.3x |
| `SURGE_THREADS=1` | GET | 5353 | 4519 | 0.8x |
| `SURGE_THREADS=1` | SET | 2672 | 2861 | 1.1x |
| `SURGE_THREADS=1` | mixed | 2700 | 2379 | 0.9x |
| `SURGE_THREADS=8` | PING | 10212 | 21851 | 2.1x |
| `SURGE_THREADS=8` | GET | 5366 | 8130 | 1.5x |
| `SURGE_THREADS=8` | SET | 3880 | 5323 | 1.4x |
| `SURGE_THREADS=8` | mixed | 4233 | 5986 | 1.4x |

Redis/Valkey pipeline rows on the same harness are roughly `0.9M-1.8M rps`.
That means the Go client and local TCP stack can drive much higher pipelined
throughput than `surgekv` currently accepts.

## Strace Snapshot

One `SURGE_THREADS=1` `ping_pipe` run under `strace -f -c` handled 20000
requests with about 20005 `write()` calls and 167 `read()` calls.

`PING` bypasses protocol parsing and the state manager, so this points at the
socket response path: `surgekv` still writes one response per command even when
many commands are already buffered.

## Batch Response Check

After batching responses for already-buffered input in `serve_client`, 32-client
rows changed as follows:

| mode | op | before rps | after rps | gain |
| --- | --- | ---: | ---: | ---: |
| `SURGE_THREADS=1` | PING pipe | 38358 | 72025 | 1.9x |
| `SURGE_THREADS=1` | GET pipe | 4519 | 8982 | 2.0x |
| `SURGE_THREADS=1` | SET pipe | 2861 | 3964 | 1.4x |
| `SURGE_THREADS=1` | mixed pipe | 2379 | 5380 | 2.3x |
| `SURGE_THREADS=8` | PING pipe | 21851 | 81806 | 3.7x |
| `SURGE_THREADS=8` | GET pipe | 8130 | 10191 | 1.3x |
| `SURGE_THREADS=8` | SET pipe | 5323 | 5737 | 1.1x |
| `SURGE_THREADS=8` | mixed pipe | 5986 | 7370 | 1.2x |

A raw `strace` run for 20000 `ping_pipe` requests after batching showed
`133` `write()` calls, `167` `read()` calls, `11` `poll()` calls, and `36`
`accept()` calls. The write-count hypothesis is confirmed for pipelined clients.

Roundtrip rows improve less than pipeline rows, so the next bottleneck is likely
per-request scheduling/manager cost rather than response syscall count alone.
