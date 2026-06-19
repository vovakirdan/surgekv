# surgekv local benchmark

Generated: 2026-06-19T15:37:16Z

## Environment

- host: Linux DESKTOP-N3J9OLI 6.6.114.1-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Mon Dec  1 20:46:23 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
- surge: surge 0.1.11-dev — "forge storms before they land" commit: 2c06665daab3 message: docs(runtime): document native async runtime built:  2026-06-19T14:53:23Z
- git: 54def1c-dirty
- go: go version go1.26.1 linux/amd64
- SURGE_THREADS: 1
- redis-server: Redis server v=7.0.15 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=e53ff17674aa6190
- valkey-server: Server v=7.2.12 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=65f5b4bb2651ba8d

## Settings

- targets: surgekv redis valkey
- requests per row: 5000
- client counts: 1 32
- operations: ping get set mixed
- keys: 50
- value bytes: 64
- timeout: 5s
- surgekv: port=39752 workers=8 shards=8 max_clients=0

## Results

| target | op | clients | requests | keys | value bytes | rps | avg us | p50 us | p95 us | p99 us | errors |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| surgekv | ping | 1 | 5000 | 50 | 64 | 8296 | 119 | 111 | 192 | 239 | 0 |
| surgekv | ping | 32 | 5000 | 50 | 64 | 21906 | 1143 | 1048 | 1267 | 1527 | 0 |
| surgekv | get | 1 | 5000 | 50 | 64 | 2520 | 396 | 372 | 480 | 551 | 0 |
| surgekv | get | 32 | 5000 | 50 | 64 | 3943 | 6063 | 4330 | 5545 | 6091 | 0 |
| surgekv | set | 1 | 5000 | 50 | 64 | 1234 | 809 | 727 | 938 | 1035 | 0 |
| surgekv | set | 32 | 5000 | 50 | 64 | 1382 | 17155 | 10763 | 14004 | 42903 | 0 |
| surgekv | mixed | 1 | 5000 | 50 | 64 | 1182 | 845 | 823 | 1031 | 1327 | 0 |
| surgekv | mixed | 32 | 5000 | 50 | 64 | 2007 | 11845 | 9469 | 11347 | 14070 | 0 |
| redis | ping | 1 | 5000 | 50 | 64 | 9093 | 109 | 103 | 168 | 231 | 0 |
| redis | ping | 32 | 5000 | 50 | 64 | 74843 | 365 | 189 | 1020 | 4644 | 0 |
| redis | get | 1 | 5000 | 50 | 64 | 8896 | 111 | 105 | 175 | 236 | 0 |
| redis | get | 32 | 5000 | 50 | 64 | 60937 | 435 | 229 | 1248 | 4980 | 0 |
| redis | set | 1 | 5000 | 50 | 64 | 9127 | 108 | 103 | 165 | 213 | 0 |
| redis | set | 32 | 5000 | 50 | 64 | 69518 | 390 | 186 | 1159 | 5506 | 0 |
| redis | mixed | 1 | 5000 | 50 | 64 | 9519 | 104 | 100 | 158 | 229 | 0 |
| redis | mixed | 32 | 5000 | 50 | 64 | 61611 | 427 | 166 | 1170 | 7560 | 0 |
| valkey | ping | 1 | 5000 | 50 | 64 | 9707 | 102 | 96 | 148 | 206 | 0 |
| valkey | ping | 32 | 5000 | 50 | 64 | 67684 | 391 | 174 | 1114 | 6125 | 0 |
| valkey | get | 1 | 5000 | 50 | 64 | 8944 | 111 | 103 | 186 | 253 | 0 |
| valkey | get | 32 | 5000 | 50 | 64 | 56594 | 461 | 186 | 1341 | 6438 | 0 |
| valkey | set | 1 | 5000 | 50 | 64 | 9651 | 102 | 98 | 143 | 219 | 0 |
| valkey | set | 32 | 5000 | 50 | 64 | 67565 | 381 | 182 | 977 | 5723 | 0 |
| valkey | mixed | 1 | 5000 | 50 | 64 | 9605 | 103 | 99 | 148 | 207 | 0 |
| valkey | mixed | 32 | 5000 | 50 | 64 | 58381 | 469 | 214 | 1340 | 6018 | 0 |

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
