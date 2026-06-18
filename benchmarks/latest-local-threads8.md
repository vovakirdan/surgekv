# surgekv local benchmark

Generated: 2026-06-18T08:05:49Z

## Environment

- host: Linux DESKTOP-N3J9OLI 6.6.114.1-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Mon Dec  1 20:46:23 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
- surge: surge 0.1.10-dev — "forge storms before they land" commit: 7f084eed392c message: Merge pull request #112 from vovakirdan/fix/issue-110-channel-fanout-stall built:  2026-06-17T17:21:10Z
- git: 8cce470-dirty
- go: go version go1.26.1 linux/amd64
- SURGE_THREADS: 8
- redis-server: Redis server v=7.0.15 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=e53ff17674aa6190
- valkey-server: Server v=7.2.12 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=65f5b4bb2651ba8d

## Settings

- targets: surgekv redis valkey
- requests per row: 5000
- client counts: 32
- operations: get set mixed
- keys: 100
- value bytes: 64
- timeout: 5s
- surgekv: port=33883 workers=8 shards=8 max_clients=0

## Results

| target | op | clients | requests | keys | value bytes | rps | avg us | p50 us | p95 us | p99 us | errors |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| surgekv | get | 32 | 5000 | 100 | 64 | 5299 | 5818 | 5388 | 9799 | 12768 | 0 |
| surgekv | set | 32 | 5000 | 100 | 64 | 4728 | 6493 | 5992 | 10897 | 14002 | 0 |
| surgekv | mixed | 32 | 5000 | 100 | 64 | 4790 | 6376 | 5820 | 10769 | 15980 | 0 |
| redis | get | 32 | 5000 | 100 | 64 | 68691 | 396 | 180 | 1251 | 5477 | 0 |
| redis | set | 32 | 5000 | 100 | 64 | 66328 | 400 | 176 | 1311 | 5359 | 0 |
| redis | mixed | 32 | 5000 | 100 | 64 | 67476 | 390 | 174 | 911 | 6423 | 0 |
| valkey | get | 32 | 5000 | 100 | 64 | 64503 | 398 | 168 | 1198 | 6253 | 0 |
| valkey | set | 32 | 5000 | 100 | 64 | 72117 | 373 | 180 | 1005 | 5291 | 0 |
| valkey | mixed | 32 | 5000 | 100 | 64 | 66448 | 399 | 176 | 1072 | 5823 | 0 |

## Notes

- The benchmark client uses one persistent TCP connection per logical client.
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
