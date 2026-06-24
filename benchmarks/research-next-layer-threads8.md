# surgekv local benchmark

Generated: 2026-06-23T12:16:06Z

## Environment

- host: Linux DESKTOP-N3J9OLI 6.6.114.1-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Mon Dec  1 20:46:23 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
- surge: surge 0.1.12-dev — "forge storms before they land" commit: 5c4a0db9d38d message: Merge pull request #150 from vovakirdan/codex/byte-array-bulk-append built:  2026-06-23T12:10:39Z
- git: 04cc3d2-dirty
- go: go version go1.26.1 linux/amd64
- SURGE_THREADS: 8
- redis-server: Redis server v=7.0.15 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=e53ff17674aa6190
- valkey-server: Server v=7.2.12 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=65f5b4bb2651ba8d

## Settings

- targets: surgekv redis valkey
- requests per row: 5000
- client counts: 1 8 32
- operations: ping ping_pipe get get_pipe
- keys: 50
- value bytes: 64
- timeout: 5s
- surgekv: port=28824 workers=8 shards=8 max_clients=0

## Results

| target | op | clients | requests | keys | value bytes | rps | avg us | p50 us | p95 us | p99 us | errors |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| surgekv | ping | 1 | 5000 | 50 | 64 | 4425 | 225 | 224 | 278 | 333 | 0 |
| surgekv | ping | 8 | 5000 | 50 | 64 | 10801 | 726 | 643 | 1524 | 1991 | 0 |
| surgekv | ping | 32 | 5000 | 50 | 64 | 9329 | 2338 | 695 | 1985 | 8667 | 0 |
| surgekv | ping_pipe | 1 | 5000 | 50 | 64 | 65121 | 15 | 15 | 15 | 15 | 0 |
| surgekv | ping_pipe | 8 | 5000 | 50 | 64 | 114640 | 61 | 61 | 68 | 68 | 0 |
| surgekv | ping_pipe | 32 | 5000 | 50 | 64 | 104554 | 183 | 171 | 298 | 300 | 0 |
| surgekv | get | 1 | 5000 | 50 | 64 | 2476 | 403 | 393 | 501 | 660 | 0 |
| surgekv | get | 8 | 5000 | 50 | 64 | 3684 | 2145 | 1937 | 4289 | 5572 | 0 |
| surgekv | get | 32 | 5000 | 50 | 64 | 5241 | 5884 | 5267 | 11826 | 16734 | 0 |
| surgekv | get_pipe | 1 | 5000 | 50 | 64 | 3671 | 272 | 272 | 272 | 272 | 0 |
| surgekv | get_pipe | 8 | 5000 | 50 | 64 | 3894 | 2013 | 2023 | 2053 | 2053 | 0 |
| surgekv | get_pipe | 32 | 5000 | 50 | 64 | 8386 | 3578 | 3641 | 3777 | 3790 | 0 |
| redis | ping | 1 | 5000 | 50 | 64 | 10256 | 96 | 92 | 142 | 224 | 0 |
| redis | ping | 8 | 5000 | 50 | 64 | 47946 | 155 | 128 | 340 | 780 | 0 |
| redis | ping | 32 | 5000 | 50 | 64 | 71418 | 360 | 154 | 1049 | 5177 | 0 |
| redis | ping_pipe | 1 | 5000 | 50 | 64 | 2351920 | 0 | 0 | 0 | 0 | 0 |
| redis | ping_pipe | 8 | 5000 | 50 | 64 | 2177097 | 0 | 1 | 1 | 1 | 0 |
| redis | ping_pipe | 32 | 5000 | 50 | 64 | 1640097 | 8 | 9 | 12 | 12 | 0 |
| redis | get | 1 | 5000 | 50 | 64 | 10315 | 96 | 92 | 137 | 189 | 0 |
| redis | get | 8 | 5000 | 50 | 64 | 48992 | 152 | 133 | 309 | 582 | 0 |
| redis | get | 32 | 5000 | 50 | 64 | 68748 | 386 | 156 | 1267 | 6026 | 0 |
| redis | get_pipe | 1 | 5000 | 50 | 64 | 1177433 | 0 | 0 | 0 | 0 | 0 |
| redis | get_pipe | 8 | 5000 | 50 | 64 | 1403444 | 4 | 4 | 5 | 5 | 0 |
| redis | get_pipe | 32 | 5000 | 50 | 64 | 1320794 | 9 | 9 | 16 | 16 | 0 |
| valkey | ping | 1 | 5000 | 50 | 64 | 10093 | 98 | 92 | 148 | 223 | 0 |
| valkey | ping | 8 | 5000 | 50 | 64 | 51181 | 150 | 130 | 302 | 591 | 0 |
| valkey | ping | 32 | 5000 | 50 | 64 | 75921 | 351 | 166 | 1042 | 4627 | 0 |
| valkey | ping_pipe | 1 | 5000 | 50 | 64 | 2013531 | 0 | 0 | 0 | 0 | 0 |
| valkey | ping_pipe | 8 | 5000 | 50 | 64 | 1954845 | 2 | 2 | 3 | 3 | 0 |
| valkey | ping_pipe | 32 | 5000 | 50 | 64 | 1616594 | 8 | 9 | 12 | 13 | 0 |
| valkey | get | 1 | 5000 | 50 | 64 | 9430 | 105 | 97 | 170 | 222 | 0 |
| valkey | get | 8 | 5000 | 50 | 64 | 48693 | 158 | 136 | 315 | 661 | 0 |
| valkey | get | 32 | 5000 | 50 | 64 | 71100 | 372 | 183 | 1073 | 4133 | 0 |
| valkey | get_pipe | 1 | 5000 | 50 | 64 | 1199601 | 0 | 0 | 0 | 0 | 0 |
| valkey | get_pipe | 8 | 5000 | 50 | 64 | 1259166 | 4 | 5 | 5 | 5 | 0 |
| valkey | get_pipe | 32 | 5000 | 50 | 64 | 1227721 | 11 | 11 | 18 | 19 | 0 |

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
