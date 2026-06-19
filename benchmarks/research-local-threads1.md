# surgekv local benchmark

Generated: 2026-06-19T15:15:05Z

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
- surgekv: port=31073 workers=8 shards=8 max_clients=0

## Results

| target | op | clients | requests | keys | value bytes | rps | avg us | p50 us | p95 us | p99 us | errors |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| surgekv | ping | 1 | 5000 | 50 | 64 | 8305 | 119 | 112 | 189 | 232 | 0 |
| surgekv | ping | 32 | 5000 | 50 | 64 | 19714 | 1199 | 948 | 1157 | 1617 | 0 |
| surgekv | get | 1 | 5000 | 50 | 64 | 1388 | 719 | 715 | 871 | 1013 | 0 |
| surgekv | get | 32 | 5000 | 50 | 64 | 1709 | 14013 | 9713 | 11723 | 13201 | 0 |
| surgekv | set | 1 | 5000 | 50 | 64 | 926 | 1079 | 1054 | 1278 | 1462 | 0 |
| surgekv | set | 32 | 5000 | 50 | 64 | 1038 | 25879 | 24709 | 29346 | 31236 | 0 |
| surgekv | mixed | 1 | 5000 | 50 | 64 | 899 | 1111 | 1124 | 1349 | 1505 | 0 |
| surgekv | mixed | 32 | 5000 | 50 | 64 | 1219 | 20531 | 17527 | 21459 | 23018 | 0 |
| redis | ping | 1 | 5000 | 50 | 64 | 9892 | 100 | 98 | 133 | 190 | 0 |
| redis | ping | 32 | 5000 | 50 | 64 | 65903 | 391 | 159 | 1242 | 5722 | 0 |
| redis | get | 1 | 5000 | 50 | 64 | 9999 | 99 | 95 | 129 | 194 | 0 |
| redis | get | 32 | 5000 | 50 | 64 | 64171 | 404 | 177 | 1207 | 5888 | 0 |
| redis | set | 1 | 5000 | 50 | 64 | 9795 | 101 | 97 | 138 | 194 | 0 |
| redis | set | 32 | 5000 | 50 | 64 | 70535 | 382 | 186 | 1069 | 4569 | 0 |
| redis | mixed | 1 | 5000 | 50 | 64 | 9768 | 101 | 96 | 145 | 190 | 0 |
| redis | mixed | 32 | 5000 | 50 | 64 | 71387 | 383 | 173 | 1147 | 5358 | 0 |
| valkey | ping | 1 | 5000 | 50 | 64 | 9831 | 100 | 98 | 145 | 186 | 0 |
| valkey | ping | 32 | 5000 | 50 | 64 | 68180 | 383 | 191 | 1111 | 5363 | 0 |
| valkey | get | 1 | 5000 | 50 | 64 | 9925 | 100 | 94 | 147 | 229 | 0 |
| valkey | get | 32 | 5000 | 50 | 64 | 70068 | 386 | 194 | 1000 | 5582 | 0 |
| valkey | set | 1 | 5000 | 50 | 64 | 9780 | 101 | 95 | 146 | 229 | 0 |
| valkey | set | 32 | 5000 | 50 | 64 | 68526 | 382 | 208 | 827 | 5965 | 0 |
| valkey | mixed | 1 | 5000 | 50 | 64 | 9823 | 101 | 95 | 147 | 232 | 0 |
| valkey | mixed | 32 | 5000 | 50 | 64 | 72959 | 371 | 187 | 1123 | 5327 | 0 |

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
