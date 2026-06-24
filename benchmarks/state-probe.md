# surgekv state probe

Generated: 2026-06-23 with Surge `0.1.12-dev` commit `5c4a0db`.

Command:

```bash
SURGE_STDLIB=/home/zov/projects/surge/surge \
/home/zov/projects/surge/surge/surge build --release benchmarks/state_probe
SURGE_THREADS=1 ./target/release/state_probe
SURGE_THREADS=4 ./target/release/state_probe
SURGE_THREADS=8 ./target/release/state_probe
```

## Results

`SURGE_THREADS=1`:

| probe | iterations | total us | ns/op |
| --- | ---: | ---: | ---: |
| direct_store_get | 50000 | 38129 | 762 |
| direct_store_set | 50000 | 97847 | 1956 |
| direct_apply_get | 50000 | 52503 | 1050 |
| direct_apply_set | 50000 | 111661 | 2233 |
| manager_get_reused_reply | 50000 | 238036 | 4760 |
| manager_set_reused_reply | 50000 | 314088 | 6281 |
| manager_apply_get_reused_reply | 50000 | 248415 | 4968 |
| manager_apply_set_reused_reply | 50000 | 330659 | 6613 |

`SURGE_THREADS=4`:

| probe | iterations | total us | ns/op |
| --- | ---: | ---: | ---: |
| direct_store_get | 50000 | 38374 | 767 |
| direct_store_set | 50000 | 97479 | 1949 |
| direct_apply_get | 50000 | 51981 | 1039 |
| direct_apply_set | 50000 | 109941 | 2198 |
| manager_get_reused_reply | 50000 | 596579 | 11931 |
| manager_set_reused_reply | 50000 | 762202 | 15244 |
| manager_apply_get_reused_reply | 50000 | 602602 | 12052 |
| manager_apply_set_reused_reply | 50000 | 770898 | 15417 |

`SURGE_THREADS=8`:

| probe | iterations | total us | ns/op |
| --- | ---: | ---: | ---: |
| direct_store_get | 50000 | 42302 | 846 |
| direct_store_set | 50000 | 100841 | 2016 |
| direct_apply_get | 50000 | 50481 | 1009 |
| direct_apply_set | 50000 | 109671 | 2193 |
| manager_get_reused_reply | 50000 | 583198 | 11663 |
| manager_set_reused_reply | 50000 | 752435 | 15048 |
| manager_apply_get_reused_reply | 50000 | 620457 | 12409 |
| manager_apply_set_reused_reply | 50000 | 815778 | 16315 |

## Notes

- Direct `Store` reads/writes are microsecond-scale and are not the current
  throughput ceiling.
- The manager channel hop is visible and thread-count sensitive, but direct
  store work is still microsecond-scale and not the current ceiling.
