# surgekv local benchmark

Generated: 2026-06-22T15:10:26Z

## Environment

- host: Linux DESKTOP-N3J9OLI 6.6.114.1-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Mon Dec  1 20:46:23 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
- surge: surge 0.1.12-dev — "forge storms before they land" commit: e7142f04a9ae message: Merge pull request #148 from vovakirdan/codex/json-validate-bytesview built:  2026-06-22T14:18:56Z
- git: b16ab2e-dirty
- go: go version go1.26.1 linux/amd64
- SURGE_THREADS: 1
- redis-server: Redis server v=7.0.15 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=e53ff17674aa6190
- valkey-server: Server v=7.2.12 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=65f5b4bb2651ba8d

## Settings

- targets: surgekv redis valkey
- requests per row: 5000
- client counts: 32
- operations: ping ping_pipe get get_pipe set set_pipe mixed mixed_pipe
- keys: 50
- value bytes: 64
- timeout: 5s
- surgekv: port=24884 workers=8 shards=8 max_clients=0

## Results

| target | op | clients | requests | keys | value bytes | rps | avg us | p50 us | p95 us | p99 us | errors |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| surgekv | ping | 32 | 5000 | 50 | 64 | 24791 | 940 | 796 | 946 | 1247 | 0 |
| surgekv | ping_pipe | 32 | 5000 | 50 | 64 | 72025 | 224 | 233 | 437 | 440 | 0 |
| surgekv | get | 32 | 5000 | 50 | 64 | 6764 | 3706 | 3257 | 3751 | 4157 | 0 |
| surgekv | get_pipe | 32 | 5000 | 50 | 64 | 8982 | 2679 | 2371 | 3548 | 3557 | 0 |
| surgekv | set | 32 | 5000 | 50 | 64 | 3718 | 7861 | 7800 | 8880 | 9613 | 0 |
| surgekv | set_pipe | 32 | 5000 | 50 | 64 | 3964 | 6801 | 6795 | 8076 | 8080 | 0 |
| surgekv | mixed | 32 | 5000 | 50 | 64 | 3858 | 6851 | 6370 | 7377 | 8534 | 0 |
| surgekv | mixed_pipe | 32 | 5000 | 50 | 64 | 5380 | 5388 | 5473 | 5689 | 5953 | 0 |
| redis | ping | 32 | 5000 | 50 | 64 | 80909 | 329 | 161 | 918 | 4510 | 0 |
| redis | ping_pipe | 32 | 5000 | 50 | 64 | 1539499 | 7 | 8 | 11 | 11 | 0 |
| redis | get | 32 | 5000 | 50 | 64 | 78418 | 334 | 185 | 825 | 3795 | 0 |
| redis | get_pipe | 32 | 5000 | 50 | 64 | 1144134 | 9 | 10 | 16 | 16 | 0 |
| redis | set | 32 | 5000 | 50 | 64 | 76529 | 352 | 168 | 1018 | 4812 | 0 |
| redis | set_pipe | 32 | 5000 | 50 | 64 | 957979 | 16 | 21 | 25 | 25 | 0 |
| redis | mixed | 32 | 5000 | 50 | 64 | 76436 | 353 | 167 | 980 | 5336 | 0 |
| redis | mixed_pipe | 32 | 5000 | 50 | 64 | 1221284 | 9 | 9 | 16 | 17 | 0 |
| valkey | ping | 32 | 5000 | 50 | 64 | 76944 | 335 | 154 | 870 | 4934 | 0 |
| valkey | ping_pipe | 32 | 5000 | 50 | 64 | 1660726 | 7 | 8 | 11 | 12 | 0 |
| valkey | get | 32 | 5000 | 50 | 64 | 73339 | 361 | 164 | 1204 | 4391 | 0 |
| valkey | get_pipe | 32 | 5000 | 50 | 64 | 1162940 | 14 | 16 | 19 | 20 | 0 |
| valkey | set | 32 | 5000 | 50 | 64 | 76769 | 343 | 178 | 936 | 4199 | 0 |
| valkey | set_pipe | 32 | 5000 | 50 | 64 | 1009545 | 13 | 13 | 21 | 22 | 0 |
| valkey | mixed | 32 | 5000 | 50 | 64 | 69424 | 368 | 158 | 1135 | 4970 | 0 |
| valkey | mixed_pipe | 32 | 5000 | 50 | 64 | 1128940 | 13 | 12 | 19 | 21 | 0 |

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
