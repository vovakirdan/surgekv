# surgekv local benchmark

Generated: 2026-06-19T15:15:40Z

## Environment

- host: Linux DESKTOP-N3J9OLI 6.6.114.1-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Mon Dec  1 20:46:23 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
- surge: surge 0.1.11-dev — "forge storms before they land" commit: 2c06665daab3 message: docs(runtime): document native async runtime built:  2026-06-19T14:53:23Z
- git: 54def1c-dirty
- go: go version go1.26.1 linux/amd64
- SURGE_THREADS: 8
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
- surgekv: port=25125 workers=8 shards=8 max_clients=0

## Results

| target | op | clients | requests | keys | value bytes | rps | avg us | p50 us | p95 us | p99 us | errors |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| surgekv | ping | 1 | 5000 | 50 | 64 | 3960 | 251 | 246 | 314 | 373 | 0 |
| surgekv | ping | 32 | 5000 | 50 | 64 | 9642 | 2106 | 666 | 1913 | 13295 | 0 |
| surgekv | get | 1 | 5000 | 50 | 64 | 1258 | 794 | 774 | 953 | 1054 | 0 |
| surgekv | get | 32 | 5000 | 50 | 64 | 2581 | 12028 | 11723 | 23489 | 33416 | 0 |
| surgekv | set | 1 | 5000 | 50 | 64 | 769 | 1300 | 1259 | 1668 | 1958 | 0 |
| surgekv | set | 32 | 5000 | 50 | 64 | 1551 | 20132 | 19641 | 39041 | 53475 | 0 |
| surgekv | mixed | 1 | 5000 | 50 | 64 | 831 | 1202 | 1242 | 1506 | 1788 | 0 |
| surgekv | mixed | 32 | 5000 | 50 | 64 | 1894 | 16501 | 15795 | 32008 | 44503 | 0 |
| redis | ping | 1 | 5000 | 50 | 64 | 10151 | 97 | 94 | 136 | 179 | 0 |
| redis | ping | 32 | 5000 | 50 | 64 | 66422 | 382 | 163 | 1143 | 5981 | 0 |
| redis | get | 1 | 5000 | 50 | 64 | 9680 | 102 | 97 | 155 | 231 | 0 |
| redis | get | 32 | 5000 | 50 | 64 | 70587 | 382 | 177 | 1119 | 5220 | 0 |
| redis | set | 1 | 5000 | 50 | 64 | 9590 | 103 | 99 | 154 | 210 | 0 |
| redis | set | 32 | 5000 | 50 | 64 | 69647 | 376 | 172 | 994 | 5578 | 0 |
| redis | mixed | 1 | 5000 | 50 | 64 | 9647 | 102 | 98 | 146 | 203 | 0 |
| redis | mixed | 32 | 5000 | 50 | 64 | 66637 | 382 | 175 | 1308 | 4772 | 0 |
| valkey | ping | 1 | 5000 | 50 | 64 | 9225 | 107 | 104 | 147 | 203 | 0 |
| valkey | ping | 32 | 5000 | 50 | 64 | 71734 | 363 | 185 | 1083 | 4664 | 0 |
| valkey | get | 1 | 5000 | 50 | 64 | 9737 | 101 | 98 | 150 | 201 | 0 |
| valkey | get | 32 | 5000 | 50 | 64 | 68861 | 393 | 188 | 1203 | 5476 | 0 |
| valkey | set | 1 | 5000 | 50 | 64 | 9454 | 105 | 100 | 156 | 205 | 0 |
| valkey | set | 32 | 5000 | 50 | 64 | 70272 | 387 | 186 | 1090 | 5612 | 0 |
| valkey | mixed | 1 | 5000 | 50 | 64 | 9634 | 103 | 98 | 148 | 205 | 0 |
| valkey | mixed | 32 | 5000 | 50 | 64 | 65032 | 409 | 184 | 1235 | 5175 | 0 |

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
