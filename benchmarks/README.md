# surgekv Benchmarks

This directory holds local benchmark reports for `surgekv`.

The harness is intentionally small:

- `scripts/bench_load.go` is a dependency-free TCP load client.
- `scripts/bench.sh` builds `surgekv`, starts an isolated server, runs a short matrix, and writes a markdown report.
- `benchmarks/state_probe` isolates direct `Store` work from the manager channel hop.
- `benchmarks/server_probe` isolates line parsing, shard routing, response bytes, and protocol pipeline cost.
- `benchmarks/json_probe` compares full JSON parsing with validate-only checks.
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
The current single-thread comparison report is
`benchmarks/latest-local-threads1.md`.
The current eight-thread comparison report is
`benchmarks/latest-local-threads8.md`.
The current runtime-layer summary is `benchmarks/runtime-layer-findings.md`.
The focused state and server primitive reports are
`benchmarks/state-probe.md`, `benchmarks/server-probe.md`, and
`benchmarks/json-probe.md`.
The routing-fix TCP comparison reports are
`benchmarks/research-hashfix-threads1.md` and
`benchmarks/research-hashfix-threads8.md`.
The JSON validate TCP comparison reports are
`benchmarks/research-jsonvalidate-threads1.md` and
`benchmarks/research-jsonvalidate-threads8.md`.

## Reading Results

Each row uses one persistent TCP connection per logical client. `mixed`
alternates `SET` and `GET` across the configured key space.

Rows with non-zero `errors` are still written. If a target fails before the
timed run, for example during preload, the harness writes a failure row with
`errors=requests` and zero latency values. That keeps process-level degradation
visible in the table instead of hiding later rows.

The first numbers to watch are:

- `errors`: must stay at zero for a valid throughput run.
- `p95 us` and `p99 us`: catch stalls better than averages.
- `rps`: useful only when compared on the same host with the same settings.

## Current Gaps

- Surge runtime/server overhead still dominates local latency versus
  Redis/Valkey, so short reports are bottleneck-finding data rather than final
  throughput claims.
- Default `surgekv`, `SURGE_THREADS=1`, and `SURGE_THREADS=8` complete the
  current 32-client stateful matrix with zero errors.
- `SURGE_THREADS=8` currently reaches about `5.6k GET rps`, `4.9k SET rps`,
  and `4.0k mixed rps`; Redis/Valkey are still around `68-79k rps` on the
  same host.
- The previous smallest confirmed trigger was short-lived connection churn plus
  synchronous disconnect cleanup fanout; current `surgekv` has moved that
  cleanup off the socket hot path.
- Clean LLVM output now emits `rt_net_read_bytes`/`rt_net_write_bytes`, and
  server `strace` shows bulk socket I/O.
- The harness does not sample process RSS yet.
- There is no long soak mode yet.
- There are no protocol-specific ownership contention scenarios yet.
