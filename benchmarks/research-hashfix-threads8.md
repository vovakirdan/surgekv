# surgekv local benchmark

Generated: 2026-06-19T15:37:42Z

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
- surgekv: port=39783 workers=8 shards=8 max_clients=0

## Results

| target | op | clients | requests | keys | value bytes | rps | avg us | p50 us | p95 us | p99 us | errors |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| surgekv | ping | 1 | 5000 | 50 | 64 | 4501 | 221 | 218 | 272 | 324 | 0 |
| surgekv | ping | 32 | 5000 | 50 | 64 | 10745 | 1951 | 621 | 1752 | 10726 | 0 |
| surgekv | get | 1 | 5000 | 50 | 64 | 2677 | 372 | 367 | 439 | 518 | 0 |
| surgekv | get | 32 | 5000 | 50 | 64 | 5344 | 5802 | 5436 | 11427 | 15906 | 0 |
| surgekv | set | 1 | 5000 | 50 | 64 | 1194 | 836 | 820 | 1016 | 1228 | 0 |
| surgekv | set | 32 | 5000 | 50 | 64 | 2532 | 12208 | 11770 | 23381 | 31101 | 0 |
| surgekv | mixed | 1 | 5000 | 50 | 64 | 1267 | 788 | 814 | 1072 | 1300 | 0 |
| surgekv | mixed | 32 | 5000 | 50 | 64 | 3117 | 9857 | 8969 | 19775 | 27408 | 0 |
| redis | ping | 1 | 5000 | 50 | 64 | 9946 | 99 | 94 | 142 | 217 | 0 |
| redis | ping | 32 | 5000 | 50 | 64 | 77505 | 357 | 187 | 1074 | 4252 | 0 |
| redis | get | 1 | 5000 | 50 | 64 | 9482 | 104 | 100 | 159 | 208 | 0 |
| redis | get | 32 | 5000 | 50 | 64 | 61676 | 426 | 173 | 1198 | 6003 | 0 |
| redis | set | 1 | 5000 | 50 | 64 | 9510 | 104 | 100 | 154 | 205 | 0 |
| redis | set | 32 | 5000 | 50 | 64 | 70812 | 384 | 181 | 1186 | 4901 | 0 |
| redis | mixed | 1 | 5000 | 50 | 64 | 9956 | 99 | 95 | 136 | 186 | 0 |
| redis | mixed | 32 | 5000 | 50 | 64 | 62221 | 431 | 213 | 1290 | 5916 | 0 |
| valkey | ping | 1 | 5000 | 50 | 64 | 9608 | 103 | 100 | 148 | 202 | 0 |
| valkey | ping | 32 | 5000 | 50 | 64 | 54034 | 476 | 182 | 1276 | 9316 | 0 |
| valkey | get | 1 | 5000 | 50 | 64 | 9583 | 103 | 99 | 150 | 209 | 0 |
| valkey | get | 32 | 5000 | 50 | 64 | 70915 | 381 | 176 | 1138 | 5338 | 0 |
| valkey | set | 1 | 5000 | 50 | 64 | 8792 | 112 | 106 | 178 | 234 | 0 |
| valkey | set | 32 | 5000 | 50 | 64 | 63536 | 426 | 189 | 1249 | 6412 | 0 |
| valkey | mixed | 1 | 5000 | 50 | 64 | 9444 | 105 | 98 | 167 | 251 | 0 |
| valkey | mixed | 32 | 5000 | 50 | 64 | 65357 | 401 | 193 | 1156 | 5679 | 0 |

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
