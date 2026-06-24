# surgekv local benchmark

Generated: 2026-06-23T12:15:50Z

## Environment

- host: Linux DESKTOP-N3J9OLI 6.6.114.1-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Mon Dec  1 20:46:23 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
- surge: surge 0.1.12-dev — "forge storms before they land" commit: 5c4a0db9d38d message: Merge pull request #150 from vovakirdan/codex/byte-array-bulk-append built:  2026-06-23T12:10:39Z
- git: 04cc3d2-dirty
- go: go version go1.26.1 linux/amd64
- SURGE_THREADS: 1
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
- surgekv: port=35605 workers=8 shards=8 max_clients=0

## Results

| target | op | clients | requests | keys | value bytes | rps | avg us | p50 us | p95 us | p99 us | errors |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| surgekv | ping | 1 | 5000 | 50 | 64 | 10153 | 97 | 89 | 168 | 215 | 0 |
| surgekv | ping | 8 | 5000 | 50 | 64 | 19321 | 333 | 295 | 418 | 673 | 0 |
| surgekv | ping | 32 | 5000 | 50 | 64 | 23508 | 1098 | 1022 | 1203 | 1447 | 0 |
| surgekv | ping_pipe | 1 | 5000 | 50 | 64 | 69705 | 14 | 14 | 14 | 14 | 0 |
| surgekv | ping_pipe | 8 | 5000 | 50 | 64 | 69320 | 92 | 94 | 114 | 114 | 0 |
| surgekv | ping_pipe | 32 | 5000 | 50 | 64 | 71651 | 223 | 215 | 441 | 442 | 0 |
| surgekv | get | 1 | 5000 | 50 | 64 | 3096 | 322 | 314 | 388 | 469 | 0 |
| surgekv | get | 8 | 5000 | 50 | 64 | 5417 | 1177 | 1017 | 1184 | 1272 | 0 |
| surgekv | get | 32 | 5000 | 50 | 64 | 4612 | 6013 | 6089 | 6970 | 7827 | 0 |
| surgekv | get_pipe | 1 | 5000 | 50 | 64 | 3796 | 263 | 263 | 263 | 263 | 0 |
| surgekv | get_pipe | 8 | 5000 | 50 | 64 | 5132 | 1201 | 1084 | 1557 | 1557 | 0 |
| surgekv | get_pipe | 32 | 5000 | 50 | 64 | 7348 | 3883 | 4131 | 4350 | 4351 | 0 |
| redis | ping | 1 | 5000 | 50 | 64 | 10543 | 94 | 88 | 143 | 199 | 0 |
| redis | ping | 8 | 5000 | 50 | 64 | 53260 | 146 | 124 | 290 | 624 | 0 |
| redis | ping | 32 | 5000 | 50 | 64 | 76416 | 358 | 168 | 1244 | 4618 | 0 |
| redis | ping_pipe | 1 | 5000 | 50 | 64 | 2195315 | 0 | 0 | 0 | 0 | 0 |
| redis | ping_pipe | 8 | 5000 | 50 | 64 | 2036261 | 1 | 2 | 2 | 2 | 0 |
| redis | ping_pipe | 32 | 5000 | 50 | 64 | 1538149 | 8 | 8 | 12 | 12 | 0 |
| redis | get | 1 | 5000 | 50 | 64 | 10647 | 93 | 88 | 136 | 210 | 0 |
| redis | get | 8 | 5000 | 50 | 64 | 52614 | 144 | 126 | 290 | 583 | 0 |
| redis | get | 32 | 5000 | 50 | 64 | 70668 | 373 | 173 | 1172 | 4965 | 0 |
| redis | get_pipe | 1 | 5000 | 50 | 64 | 1196953 | 0 | 0 | 0 | 0 | 0 |
| redis | get_pipe | 8 | 5000 | 50 | 64 | 1480785 | 2 | 3 | 4 | 4 | 0 |
| redis | get_pipe | 32 | 5000 | 50 | 64 | 1195299 | 12 | 14 | 17 | 17 | 0 |
| valkey | ping | 1 | 5000 | 50 | 64 | 10370 | 95 | 92 | 140 | 198 | 0 |
| valkey | ping | 8 | 5000 | 50 | 64 | 45447 | 162 | 139 | 333 | 715 | 0 |
| valkey | ping | 32 | 5000 | 50 | 64 | 69841 | 375 | 160 | 938 | 5773 | 0 |
| valkey | ping_pipe | 1 | 5000 | 50 | 64 | 2202892 | 0 | 0 | 0 | 0 | 0 |
| valkey | ping_pipe | 8 | 5000 | 50 | 64 | 1918490 | 2 | 2 | 3 | 3 | 0 |
| valkey | ping_pipe | 32 | 5000 | 50 | 64 | 1638209 | 7 | 8 | 11 | 11 | 0 |
| valkey | get | 1 | 5000 | 50 | 64 | 10126 | 98 | 93 | 146 | 215 | 0 |
| valkey | get | 8 | 5000 | 50 | 64 | 49452 | 156 | 136 | 317 | 565 | 0 |
| valkey | get | 32 | 5000 | 50 | 64 | 73761 | 363 | 189 | 1151 | 4691 | 0 |
| valkey | get_pipe | 1 | 5000 | 50 | 64 | 1210273 | 0 | 0 | 0 | 0 | 0 |
| valkey | get_pipe | 8 | 5000 | 50 | 64 | 1414996 | 4 | 4 | 4 | 4 | 0 |
| valkey | get_pipe | 32 | 5000 | 50 | 64 | 981835 | 9 | 9 | 15 | 21 | 0 |

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
