# surgekv local benchmark

Generated: 2026-06-22T14:57:58Z

## Environment

- host: Linux DESKTOP-N3J9OLI 6.6.114.1-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Mon Dec  1 20:46:23 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
- surge: surge 0.1.12-dev — "forge storms before they land" commit: e7142f04a9ae message: Merge pull request #148 from vovakirdan/codex/json-validate-bytesview built:  2026-06-22T14:18:56Z
- git: b16ab2e-dirty
- go: go version go1.26.1 linux/amd64
- SURGE_THREADS: 8
- redis-server: Redis server v=7.0.15 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=e53ff17674aa6190
- valkey-server: Server v=7.2.12 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=65f5b4bb2651ba8d

## Settings

- targets: surgekv redis valkey
- requests per row: 5000
- client counts: 1 32
- operations: ping ping_pipe get get_pipe set set_pipe mixed mixed_pipe
- keys: 50
- value bytes: 64
- timeout: 5s
- surgekv: port=32735 workers=8 shards=8 max_clients=0

## Results

| target | op | clients | requests | keys | value bytes | rps | avg us | p50 us | p95 us | p99 us | errors |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| surgekv | ping | 1 | 5000 | 50 | 64 | 4539 | 219 | 217 | 274 | 325 | 0 |
| surgekv | ping | 32 | 5000 | 50 | 64 | 10212 | 2092 | 637 | 1883 | 12424 | 0 |
| surgekv | ping_pipe | 1 | 5000 | 50 | 64 | 9101 | 109 | 109 | 109 | 109 | 0 |
| surgekv | ping_pipe | 32 | 5000 | 50 | 64 | 21851 | 927 | 810 | 1444 | 1457 | 0 |
| surgekv | get | 1 | 5000 | 50 | 64 | 2346 | 425 | 414 | 527 | 757 | 0 |
| surgekv | get | 32 | 5000 | 50 | 64 | 5366 | 5700 | 5102 | 10959 | 15339 | 0 |
| surgekv | get_pipe | 1 | 5000 | 50 | 64 | 3285 | 304 | 304 | 304 | 304 | 0 |
| surgekv | get_pipe | 32 | 5000 | 50 | 64 | 8130 | 3780 | 3815 | 3925 | 3938 | 0 |
| surgekv | set | 1 | 5000 | 50 | 64 | 1523 | 655 | 637 | 826 | 1193 | 0 |
| surgekv | set | 32 | 5000 | 50 | 64 | 3880 | 8008 | 7356 | 15553 | 21556 | 0 |
| surgekv | set_pipe | 1 | 5000 | 50 | 64 | 1906 | 524 | 524 | 524 | 524 | 0 |
| surgekv | set_pipe | 32 | 5000 | 50 | 64 | 5323 | 5824 | 5856 | 5995 | 6013 | 0 |
| surgekv | mixed | 1 | 5000 | 50 | 64 | 1654 | 603 | 597 | 756 | 943 | 0 |
| surgekv | mixed | 32 | 5000 | 50 | 64 | 4233 | 7323 | 6653 | 14847 | 21326 | 0 |
| surgekv | mixed_pipe | 1 | 5000 | 50 | 64 | 2142 | 466 | 466 | 466 | 466 | 0 |
| surgekv | mixed_pipe | 32 | 5000 | 50 | 64 | 5986 | 5109 | 5160 | 5329 | 5341 | 0 |
| redis | ping | 1 | 5000 | 50 | 64 | 10999 | 90 | 88 | 123 | 168 | 0 |
| redis | ping | 32 | 5000 | 50 | 64 | 76605 | 336 | 167 | 820 | 5366 | 0 |
| redis | ping_pipe | 1 | 5000 | 50 | 64 | 2500711 | 0 | 0 | 0 | 0 | 0 |
| redis | ping_pipe | 32 | 5000 | 50 | 64 | 1740219 | 7 | 7 | 12 | 13 | 0 |
| redis | get | 1 | 5000 | 50 | 64 | 10996 | 90 | 86 | 129 | 185 | 0 |
| redis | get | 32 | 5000 | 50 | 64 | 69685 | 367 | 158 | 908 | 6833 | 0 |
| redis | get_pipe | 1 | 5000 | 50 | 64 | 1140141 | 0 | 0 | 0 | 0 | 0 |
| redis | get_pipe | 32 | 5000 | 50 | 64 | 1180159 | 16 | 16 | 19 | 20 | 0 |
| redis | set | 1 | 5000 | 50 | 64 | 10375 | 95 | 91 | 146 | 190 | 0 |
| redis | set | 32 | 5000 | 50 | 64 | 73190 | 362 | 158 | 943 | 5371 | 0 |
| redis | set_pipe | 1 | 5000 | 50 | 64 | 1071772 | 0 | 0 | 0 | 0 | 0 |
| redis | set_pipe | 32 | 5000 | 50 | 64 | 946484 | 17 | 21 | 23 | 28 | 0 |
| redis | mixed | 1 | 5000 | 50 | 64 | 11154 | 88 | 85 | 120 | 183 | 0 |
| redis | mixed | 32 | 5000 | 50 | 64 | 73110 | 357 | 184 | 1011 | 5492 | 0 |
| redis | mixed_pipe | 1 | 5000 | 50 | 64 | 1130407 | 0 | 0 | 0 | 0 | 0 |
| redis | mixed_pipe | 32 | 5000 | 50 | 64 | 1245941 | 9 | 12 | 14 | 15 | 0 |
| valkey | ping | 1 | 5000 | 50 | 64 | 11082 | 89 | 86 | 125 | 181 | 0 |
| valkey | ping | 32 | 5000 | 50 | 64 | 81618 | 351 | 165 | 980 | 4994 | 0 |
| valkey | ping_pipe | 1 | 5000 | 50 | 64 | 2344539 | 0 | 0 | 0 | 0 | 0 |
| valkey | ping_pipe | 32 | 5000 | 50 | 64 | 1794051 | 6 | 7 | 10 | 10 | 0 |
| valkey | get | 1 | 5000 | 50 | 64 | 10683 | 92 | 88 | 134 | 198 | 0 |
| valkey | get | 32 | 5000 | 50 | 64 | 70725 | 373 | 159 | 1010 | 5235 | 0 |
| valkey | get_pipe | 1 | 5000 | 50 | 64 | 1238660 | 0 | 0 | 0 | 0 | 0 |
| valkey | get_pipe | 32 | 5000 | 50 | 64 | 1220881 | 14 | 15 | 18 | 21 | 0 |
| valkey | set | 1 | 5000 | 50 | 64 | 10477 | 94 | 89 | 147 | 209 | 0 |
| valkey | set | 32 | 5000 | 50 | 64 | 73214 | 360 | 161 | 1046 | 5710 | 0 |
| valkey | set_pipe | 1 | 5000 | 50 | 64 | 973859 | 0 | 0 | 0 | 0 | 0 |
| valkey | set_pipe | 32 | 5000 | 50 | 64 | 1092465 | 14 | 19 | 22 | 22 | 0 |
| valkey | mixed | 1 | 5000 | 50 | 64 | 10547 | 94 | 89 | 141 | 193 | 0 |
| valkey | mixed | 32 | 5000 | 50 | 64 | 71735 | 371 | 167 | 1228 | 4873 | 0 |
| valkey | mixed_pipe | 1 | 5000 | 50 | 64 | 1086195 | 0 | 0 | 0 | 0 | 0 |
| valkey | mixed_pipe | 32 | 5000 | 50 | 64 | 996828 | 16 | 18 | 23 | 25 | 0 |

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
