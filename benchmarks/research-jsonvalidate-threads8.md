# surgekv local benchmark

Generated: 2026-06-22T14:22:48Z

## Environment

- host: Linux DESKTOP-N3J9OLI 6.6.114.1-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Mon Dec  1 20:46:23 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
- surge: surge 0.1.12-dev — "forge storms before they land" commit: e7142f04a9ae message: Merge pull request #148 from vovakirdan/codex/json-validate-bytesview built:  2026-06-22T14:19:47Z
- git: 8dcf049-dirty
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
- surgekv: port=27059 workers=8 shards=8 max_clients=0

## Results

| target | op | clients | requests | keys | value bytes | rps | avg us | p50 us | p95 us | p99 us | errors |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| surgekv | ping | 1 | 5000 | 50 | 64 | 4576 | 217 | 216 | 270 | 308 | 0 |
| surgekv | ping | 32 | 5000 | 50 | 64 | 10187 | 1960 | 633 | 1775 | 12555 | 0 |
| surgekv | get | 1 | 5000 | 50 | 64 | 2558 | 390 | 370 | 532 | 792 | 0 |
| surgekv | get | 32 | 5000 | 50 | 64 | 5594 | 5537 | 5099 | 11088 | 16082 | 0 |
| surgekv | set | 1 | 5000 | 50 | 64 | 1769 | 564 | 549 | 688 | 969 | 0 |
| surgekv | set | 32 | 5000 | 50 | 64 | 4894 | 6292 | 5928 | 12137 | 15715 | 0 |
| surgekv | mixed | 1 | 5000 | 50 | 64 | 1659 | 601 | 587 | 768 | 1129 | 0 |
| surgekv | mixed | 32 | 5000 | 50 | 64 | 3967 | 7821 | 7139 | 14758 | 20592 | 0 |
| redis | ping | 1 | 5000 | 50 | 64 | 11319 | 87 | 83 | 126 | 179 | 0 |
| redis | ping | 32 | 5000 | 50 | 64 | 71259 | 364 | 152 | 988 | 5184 | 0 |
| redis | get | 1 | 5000 | 50 | 64 | 10679 | 92 | 89 | 139 | 179 | 0 |
| redis | get | 32 | 5000 | 50 | 64 | 70922 | 374 | 158 | 1218 | 5006 | 0 |
| redis | set | 1 | 5000 | 50 | 64 | 10762 | 92 | 89 | 132 | 187 | 0 |
| redis | set | 32 | 5000 | 50 | 64 | 74585 | 360 | 160 | 1134 | 4877 | 0 |
| redis | mixed | 1 | 5000 | 50 | 64 | 10765 | 92 | 88 | 134 | 181 | 0 |
| redis | mixed | 32 | 5000 | 50 | 64 | 73285 | 366 | 158 | 1237 | 5598 | 0 |
| valkey | ping | 1 | 5000 | 50 | 64 | 10702 | 92 | 89 | 139 | 185 | 0 |
| valkey | ping | 32 | 5000 | 50 | 64 | 74981 | 339 | 151 | 904 | 4060 | 0 |
| valkey | get | 1 | 5000 | 50 | 64 | 10373 | 95 | 88 | 151 | 209 | 0 |
| valkey | get | 32 | 5000 | 50 | 64 | 67709 | 391 | 159 | 1250 | 5692 | 0 |
| valkey | set | 1 | 5000 | 50 | 64 | 10653 | 93 | 88 | 137 | 182 | 0 |
| valkey | set | 32 | 5000 | 50 | 64 | 74437 | 358 | 167 | 1039 | 5083 | 0 |
| valkey | mixed | 1 | 5000 | 50 | 64 | 10684 | 92 | 87 | 140 | 208 | 0 |
| valkey | mixed | 32 | 5000 | 50 | 64 | 70098 | 371 | 164 | 984 | 5706 | 0 |

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
