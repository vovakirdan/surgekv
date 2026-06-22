# surgekv local benchmark

Generated: 2026-06-22T14:22:23Z

## Environment

- host: Linux DESKTOP-N3J9OLI 6.6.114.1-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Mon Dec  1 20:46:23 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
- surge: surge 0.1.12-dev — "forge storms before they land" commit: e7142f04a9ae message: Merge pull request #148 from vovakirdan/codex/json-validate-bytesview built:  2026-06-22T14:19:47Z
- git: 8dcf049-dirty
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
- surgekv: port=43487 workers=8 shards=8 max_clients=0

## Results

| target | op | clients | requests | keys | value bytes | rps | avg us | p50 us | p95 us | p99 us | errors |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| surgekv | ping | 1 | 5000 | 50 | 64 | 10126 | 98 | 91 | 166 | 209 | 0 |
| surgekv | ping | 32 | 5000 | 50 | 64 | 29132 | 970 | 956 | 1105 | 1470 | 0 |
| surgekv | get | 1 | 5000 | 50 | 64 | 3361 | 296 | 308 | 378 | 425 | 0 |
| surgekv | get | 32 | 5000 | 50 | 64 | 5132 | 4961 | 4548 | 5224 | 6990 | 0 |
| surgekv | set | 1 | 5000 | 50 | 64 | 2192 | 455 | 444 | 596 | 657 | 0 |
| surgekv | set | 32 | 5000 | 50 | 64 | 2757 | 9033 | 7825 | 8738 | 9891 | 0 |
| surgekv | mixed | 1 | 5000 | 50 | 64 | 1740 | 573 | 577 | 685 | 776 | 0 |
| surgekv | mixed | 32 | 5000 | 50 | 64 | 3228 | 8131 | 7568 | 8521 | 9542 | 0 |
| redis | ping | 1 | 5000 | 50 | 64 | 10758 | 92 | 89 | 134 | 177 | 0 |
| redis | ping | 32 | 5000 | 50 | 64 | 76872 | 343 | 148 | 1102 | 5158 | 0 |
| redis | get | 1 | 5000 | 50 | 64 | 11394 | 87 | 83 | 121 | 159 | 0 |
| redis | get | 32 | 5000 | 50 | 64 | 71663 | 366 | 169 | 1079 | 4668 | 0 |
| redis | set | 1 | 5000 | 50 | 64 | 10394 | 95 | 89 | 150 | 217 | 0 |
| redis | set | 32 | 5000 | 50 | 64 | 71282 | 368 | 154 | 1032 | 5182 | 0 |
| redis | mixed | 1 | 5000 | 50 | 64 | 11123 | 89 | 85 | 126 | 169 | 0 |
| redis | mixed | 32 | 5000 | 50 | 64 | 75760 | 358 | 170 | 1178 | 5016 | 0 |
| valkey | ping | 1 | 5000 | 50 | 64 | 10762 | 92 | 89 | 131 | 183 | 0 |
| valkey | ping | 32 | 5000 | 50 | 64 | 78965 | 352 | 164 | 1099 | 4853 | 0 |
| valkey | get | 1 | 5000 | 50 | 64 | 10803 | 91 | 88 | 134 | 183 | 0 |
| valkey | get | 32 | 5000 | 50 | 64 | 73220 | 371 | 153 | 1238 | 5285 | 0 |
| valkey | set | 1 | 5000 | 50 | 64 | 10286 | 96 | 92 | 148 | 196 | 0 |
| valkey | set | 32 | 5000 | 50 | 64 | 77570 | 341 | 163 | 1002 | 4317 | 0 |
| valkey | mixed | 1 | 5000 | 50 | 64 | 10723 | 92 | 89 | 133 | 174 | 0 |
| valkey | mixed | 32 | 5000 | 50 | 64 | 75549 | 350 | 160 | 1061 | 5241 | 0 |

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
