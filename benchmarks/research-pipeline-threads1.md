# surgekv local benchmark

Generated: 2026-06-22T14:57:20Z

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
- client counts: 1 32
- operations: ping ping_pipe get get_pipe set set_pipe mixed mixed_pipe
- keys: 50
- value bytes: 64
- timeout: 5s
- surgekv: port=29123 workers=8 shards=8 max_clients=0

## Results

| target | op | clients | requests | keys | value bytes | rps | avg us | p50 us | p95 us | p99 us | errors |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| surgekv | ping | 1 | 5000 | 50 | 64 | 10375 | 95 | 89 | 154 | 203 | 0 |
| surgekv | ping | 32 | 5000 | 50 | 64 | 29505 | 732 | 449 | 564 | 1828 | 0 |
| surgekv | ping_pipe | 1 | 5000 | 50 | 64 | 25284 | 39 | 39 | 39 | 39 | 0 |
| surgekv | ping_pipe | 32 | 5000 | 50 | 64 | 38358 | 717 | 713 | 830 | 830 | 0 |
| surgekv | get | 1 | 5000 | 50 | 64 | 2958 | 337 | 334 | 393 | 449 | 0 |
| surgekv | get | 32 | 5000 | 50 | 64 | 5353 | 5177 | 5018 | 5653 | 6487 | 0 |
| surgekv | get_pipe | 1 | 5000 | 50 | 64 | 3995 | 250 | 250 | 250 | 250 | 0 |
| surgekv | get_pipe | 32 | 5000 | 50 | 64 | 4519 | 5968 | 5851 | 7080 | 7083 | 0 |
| surgekv | set | 1 | 5000 | 50 | 64 | 1573 | 634 | 634 | 698 | 798 | 0 |
| surgekv | set | 32 | 5000 | 50 | 64 | 2672 | 9208 | 7755 | 8556 | 9527 | 0 |
| surgekv | set_pipe | 1 | 5000 | 50 | 64 | 2323 | 430 | 430 | 430 | 430 | 0 |
| surgekv | set_pipe | 32 | 5000 | 50 | 64 | 2861 | 8419 | 11110 | 11192 | 11196 | 0 |
| surgekv | mixed | 1 | 5000 | 50 | 64 | 1726 | 578 | 580 | 683 | 740 | 0 |
| surgekv | mixed | 32 | 5000 | 50 | 64 | 2700 | 10152 | 8776 | 12473 | 14251 | 0 |
| surgekv | mixed_pipe | 1 | 5000 | 50 | 64 | 1746 | 572 | 572 | 572 | 572 | 0 |
| surgekv | mixed_pipe | 32 | 5000 | 50 | 64 | 2379 | 10142 | 13363 | 13442 | 13460 | 0 |
| redis | ping | 1 | 5000 | 50 | 64 | 11066 | 89 | 87 | 124 | 167 | 0 |
| redis | ping | 32 | 5000 | 50 | 64 | 80848 | 309 | 157 | 890 | 4212 | 0 |
| redis | ping_pipe | 1 | 5000 | 50 | 64 | 2316953 | 0 | 0 | 0 | 0 | 0 |
| redis | ping_pipe | 32 | 5000 | 50 | 64 | 1847583 | 8 | 10 | 11 | 12 | 0 |
| redis | get | 1 | 5000 | 50 | 64 | 10903 | 91 | 89 | 125 | 173 | 0 |
| redis | get | 32 | 5000 | 50 | 64 | 74048 | 363 | 165 | 935 | 5527 | 0 |
| redis | get_pipe | 1 | 5000 | 50 | 64 | 1224653 | 0 | 0 | 0 | 0 | 0 |
| redis | get_pipe | 32 | 5000 | 50 | 64 | 1175451 | 10 | 10 | 14 | 14 | 0 |
| redis | set | 1 | 5000 | 50 | 64 | 11073 | 89 | 85 | 125 | 175 | 0 |
| redis | set | 32 | 5000 | 50 | 64 | 80445 | 336 | 168 | 1037 | 3931 | 0 |
| redis | set_pipe | 1 | 5000 | 50 | 64 | 1092826 | 0 | 0 | 0 | 0 | 0 |
| redis | set_pipe | 32 | 5000 | 50 | 64 | 1071597 | 14 | 17 | 20 | 21 | 0 |
| redis | mixed | 1 | 5000 | 50 | 64 | 10412 | 95 | 89 | 155 | 209 | 0 |
| redis | mixed | 32 | 5000 | 50 | 64 | 70283 | 365 | 161 | 1015 | 4616 | 0 |
| redis | mixed_pipe | 1 | 5000 | 50 | 64 | 1060329 | 0 | 0 | 0 | 0 | 0 |
| redis | mixed_pipe | 32 | 5000 | 50 | 64 | 1225395 | 11 | 12 | 17 | 18 | 0 |
| valkey | ping | 1 | 5000 | 50 | 64 | 10761 | 92 | 89 | 135 | 172 | 0 |
| valkey | ping | 32 | 5000 | 50 | 64 | 79676 | 338 | 154 | 979 | 4302 | 0 |
| valkey | ping_pipe | 1 | 5000 | 50 | 64 | 2426416 | 0 | 0 | 0 | 0 | 0 |
| valkey | ping_pipe | 32 | 5000 | 50 | 64 | 1852045 | 7 | 9 | 11 | 11 | 0 |
| valkey | get | 1 | 5000 | 50 | 64 | 10818 | 91 | 88 | 129 | 168 | 0 |
| valkey | get | 32 | 5000 | 50 | 64 | 67080 | 399 | 170 | 1250 | 5986 | 0 |
| valkey | get_pipe | 1 | 5000 | 50 | 64 | 1235282 | 0 | 0 | 0 | 0 | 0 |
| valkey | get_pipe | 32 | 5000 | 50 | 64 | 958747 | 14 | 17 | 25 | 25 | 0 |
| valkey | set | 1 | 5000 | 50 | 64 | 10862 | 91 | 87 | 128 | 163 | 0 |
| valkey | set | 32 | 5000 | 50 | 64 | 70880 | 353 | 172 | 1005 | 5084 | 0 |
| valkey | set_pipe | 1 | 5000 | 50 | 64 | 1050860 | 0 | 0 | 0 | 0 | 0 |
| valkey | set_pipe | 32 | 5000 | 50 | 64 | 903991 | 19 | 22 | 24 | 27 | 0 |
| valkey | mixed | 1 | 5000 | 50 | 64 | 10268 | 96 | 92 | 146 | 183 | 0 |
| valkey | mixed | 32 | 5000 | 50 | 64 | 66620 | 404 | 155 | 1565 | 5394 | 0 |
| valkey | mixed_pipe | 1 | 5000 | 50 | 64 | 1049388 | 0 | 0 | 0 | 0 | 0 |
| valkey | mixed_pipe | 32 | 5000 | 50 | 64 | 1247390 | 13 | 16 | 19 | 20 | 0 |

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
