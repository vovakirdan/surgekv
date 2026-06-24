# surgekv local benchmark

Generated: 2026-06-22T15:10:46Z

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
- client counts: 32
- operations: ping ping_pipe get get_pipe set set_pipe mixed mixed_pipe
- keys: 50
- value bytes: 64
- timeout: 5s
- surgekv: port=24874 workers=8 shards=8 max_clients=0

## Results

| target | op | clients | requests | keys | value bytes | rps | avg us | p50 us | p95 us | p99 us | errors |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| surgekv | ping | 32 | 5000 | 50 | 64 | 11286 | 1846 | 600 | 1489 | 12650 | 0 |
| surgekv | ping_pipe | 32 | 5000 | 50 | 64 | 81806 | 241 | 218 | 384 | 386 | 0 |
| surgekv | get | 32 | 5000 | 50 | 64 | 6832 | 4516 | 4190 | 8911 | 12697 | 0 |
| surgekv | get_pipe | 32 | 5000 | 50 | 64 | 10191 | 3031 | 3070 | 3129 | 3132 | 0 |
| surgekv | set | 32 | 5000 | 50 | 64 | 5209 | 5898 | 5528 | 11209 | 15234 | 0 |
| surgekv | set_pipe | 32 | 5000 | 50 | 64 | 5737 | 5366 | 5424 | 5575 | 5578 | 0 |
| surgekv | mixed | 32 | 5000 | 50 | 64 | 5306 | 5805 | 5317 | 11084 | 15587 | 0 |
| surgekv | mixed_pipe | 32 | 5000 | 50 | 64 | 7370 | 4165 | 4231 | 4338 | 4338 | 0 |
| redis | ping | 32 | 5000 | 50 | 64 | 78680 | 335 | 160 | 1025 | 4410 | 0 |
| redis | ping_pipe | 32 | 5000 | 50 | 64 | 1826313 | 7 | 9 | 11 | 11 | 0 |
| redis | get | 32 | 5000 | 50 | 64 | 75160 | 351 | 172 | 869 | 5539 | 0 |
| redis | get_pipe | 32 | 5000 | 50 | 64 | 1313713 | 10 | 9 | 16 | 17 | 0 |
| redis | set | 32 | 5000 | 50 | 64 | 75238 | 346 | 173 | 944 | 4051 | 0 |
| redis | set_pipe | 32 | 5000 | 50 | 64 | 982282 | 15 | 16 | 22 | 24 | 0 |
| redis | mixed | 32 | 5000 | 50 | 64 | 72185 | 367 | 181 | 1158 | 4595 | 0 |
| redis | mixed_pipe | 32 | 5000 | 50 | 64 | 1186159 | 12 | 13 | 17 | 17 | 0 |
| valkey | ping | 32 | 5000 | 50 | 64 | 77706 | 348 | 168 | 919 | 5425 | 0 |
| valkey | ping_pipe | 32 | 5000 | 50 | 64 | 1550786 | 5 | 6 | 9 | 10 | 0 |
| valkey | get | 32 | 5000 | 50 | 64 | 70231 | 385 | 163 | 1577 | 5473 | 0 |
| valkey | get_pipe | 32 | 5000 | 50 | 64 | 1225532 | 11 | 9 | 19 | 19 | 0 |
| valkey | set | 32 | 5000 | 50 | 64 | 73748 | 354 | 184 | 1109 | 4557 | 0 |
| valkey | set_pipe | 32 | 5000 | 50 | 64 | 1064101 | 13 | 14 | 21 | 22 | 0 |
| valkey | mixed | 32 | 5000 | 50 | 64 | 71349 | 373 | 165 | 1277 | 5221 | 0 |
| valkey | mixed_pipe | 32 | 5000 | 50 | 64 | 1237778 | 12 | 13 | 17 | 18 | 0 |

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
