# surgekv local benchmark

Generated: 2026-06-23T12:03:52Z

## Environment

- host: Linux DESKTOP-N3J9OLI 6.6.114.1-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Mon Dec  1 20:46:23 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
- surge: surge 0.1.12-dev — "forge storms before they land" commit: 5c4a0db9d38d message: Merge pull request #150 from vovakirdan/codex/byte-array-bulk-append built:  2026-06-23T12:00:07Z
- git: 04cc3d2-dirty
- go: go version go1.26.1 linux/amd64
- SURGE_THREADS: default
- redis-server: Redis server v=7.0.15 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=e53ff17674aa6190
- valkey-server: Server v=7.2.12 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=65f5b4bb2651ba8d

## Settings

- targets: surgekv redis valkey
- requests per row: 5000
- client counts: 1 8 32
- operations: get
- keys: 50
- value bytes: 64
- timeout: 5s
- surgekv: port=26994 workers=8 shards=8 max_clients=0

## Results

| target | op | clients | requests | keys | value bytes | rps | avg us | p50 us | p95 us | p99 us | errors |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| surgekv | get | 1 | 5000 | 50 | 64 | 3412 | 292 | 287 | 364 | 432 | 0 |
| surgekv | get | 8 | 5000 | 50 | 64 | 3003 | 2644 | 2486 | 5086 | 6678 | 0 |
| surgekv | get | 32 | 5000 | 50 | 64 | 5397 | 5553 | 4849 | 11045 | 15843 | 0 |
| redis | get | 1 | 5000 | 50 | 64 | 10445 | 95 | 92 | 131 | 191 | 0 |
| redis | get | 8 | 5000 | 50 | 64 | 52134 | 149 | 132 | 300 | 622 | 0 |
| redis | get | 32 | 5000 | 50 | 64 | 68751 | 376 | 168 | 980 | 4729 | 0 |
| valkey | get | 1 | 5000 | 50 | 64 | 10430 | 95 | 90 | 138 | 193 | 0 |
| valkey | get | 8 | 5000 | 50 | 64 | 49697 | 156 | 138 | 315 | 564 | 0 |
| valkey | get | 32 | 5000 | 50 | 64 | 63985 | 402 | 164 | 1210 | 5764 | 0 |

## Notes

- The benchmark client uses one persistent TCP connection per logical client.
- `*_pipe` rows write each worker batch with one flush; latency columns are amortized per-request batch time.
- `mixed` alternates SET and GET over the same key space.
- The script starts isolated local Redis/Valkey processes only when their server binaries are installed.
- Rows with non-zero errors are still recorded so partial capacity failures stay visible.
- Rows with rps/latency set to 0 and errors=requests failed before the timed run, usually during preload.

## TODO

- Add long soak runs with memory sampling after the short matrix is stable.
- Add idle-client scaling runs to validate `--max-clients` and task retention behavior.
- Add hot-key contention runs with OWN/BORROW/RELEASE traffic.
- Add disconnect-churn runs to quantify O(entries) cleanup cost.
- Add TTL churn runs to measure stale expiry-record cleanup.
