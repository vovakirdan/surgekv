# surgekv local benchmark

Generated: 2026-06-16T16:01:53Z

## Environment

- host: Linux DESKTOP-N3J9OLI 6.6.114.1-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Mon Dec  1 20:46:23 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
- surge: surge 0.1.10-dev — "forge storms before they land" commit: b6a2c18175dd message: Merge pull request #101 from vovakirdan/hash-foundation-plan-main built:  2026-06-16T11:20:45Z
- git: 2c6c639-dirty
- go: go version go1.26.1 linux/amd64
- SURGE_THREADS: default
- redis-server: not installed
- valkey-server: not installed

## Settings

- targets: surgekv
- requests per row: 200
- client counts: 1 8 32
- operations: ping get set mixed
- keys: 50
- value bytes: 64
- timeout: 5s
- surgekv: port=25406 workers=8 shards=8 max_clients=0

## Results

| target | op | clients | requests | keys | value bytes | rps | avg us | p50 us | p95 us | p99 us | errors |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| surgekv | ping | 1 | 200 | 50 | 64 | 20 | 50829 | 51556 | 55677 | 56128 | 0 |
| surgekv | ping | 8 | 200 | 50 | 64 | 163 | 48868 | 51185 | 55636 | 55979 | 0 |
| surgekv | ping | 32 | 200 | 50 | 64 | 635 | 42801 | 44036 | 48188 | 48876 | 0 |
| surgekv | get | 1 | 200 | 50 | 64 | 19 | 51758 | 51987 | 56369 | 57254 | 0 |
| surgekv | get | 8 | 200 | 50 | 64 | 183 | 43296 | 44058 | 48057 | 51384 | 0 |
| surgekv | get | 32 | 200 | 50 | 64 | 633 | 43300 | 44097 | 51926 | 53280 | 0 |
| surgekv | set | 1 | 200 | 50 | 64 | 20 | 50355 | 51105 | 54301 | 55627 | 0 |
| surgekv | set | 8 | 200 | 50 | 64 | 173 | 46018 | 46003 | 54342 | 56001 | 0 |
| surgekv | set | 32 | 200 | 50 | 64 | 577 | 44465 | 44220 | 52568 | 55966 | 0 |
| surgekv | mixed | 1 | 200 | 50 | 64 | 20 | 50867 | 51505 | 54886 | 56012 | 0 |
| surgekv | mixed | 8 | 200 | 50 | 64 | 160 | 49843 | 51570 | 56050 | 58042 | 0 |
| surgekv | mixed | 32 | 200 | 50 | 64 | 578 | 45051 | 46464 | 53125 | 59838 | 0 |

## Notes

- The benchmark client uses one persistent TCP connection per logical client.
- `mixed` alternates SET and GET over the same key space.
- The script starts isolated local Redis/Valkey processes only when their server binaries are installed.
- Current local numbers are strongly shaped by Surge runtime network polling; default multi-worker runs show roughly 50 ms per single-client request on this host.
- Skipped targets: redis, valkey.

## TODO

- Add long soak runs with memory sampling after the short matrix is stable.
- Add idle-client scaling runs to validate `--max-clients` and task retention behavior.
- Add hot-key contention runs with OWN/BORROW/RELEASE traffic.
- Add disconnect-churn runs to quantify O(entries) cleanup cost.
- Add TTL churn runs to measure stale expiry-record cleanup.
- Compare against Redis/Valkey on the same host once those binaries are installed.
