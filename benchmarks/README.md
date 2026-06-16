# surgekv Benchmarks

This directory holds local benchmark reports for `surgekv`.

The harness is intentionally small:

- `scripts/bench_load.go` is a dependency-free TCP load client.
- `scripts/bench.sh` builds `surgekv`, starts an isolated server, runs a short matrix, and writes a markdown report.
- Redis and Valkey are included automatically when `redis-server` or `valkey-server` are installed.

Run the default local matrix:

```bash
./scripts/bench.sh
```

Useful overrides:

```bash
SURGEKV_BENCH_REQUESTS=50000 \
SURGEKV_BENCH_CLIENTS="1 8 32 128" \
SURGEKV_BENCH_OPS="ping get set mixed" \
./scripts/bench.sh
```

The default report path is `benchmarks/latest-local.md`.

## Reading Results

Each row uses one persistent TCP connection per logical client. `mixed`
alternates `SET` and `GET` across the configured key space.

The first numbers to watch are:

- `errors`: must stay at zero for a valid throughput run.
- `p95 us` and `p99 us`: catch stalls better than averages.
- `rps`: useful only when compared on the same host with the same settings.

## Current Gaps

- The harness does not sample process RSS yet.
- There is no long soak mode yet.
- There are no protocol-specific ownership contention scenarios yet.
- Redis/Valkey comparison requires their server binaries to be installed on the same host.
