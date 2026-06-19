# surgekv state probe

Generated: 2026-06-19 with Surge `0.1.11-dev` commit `2c06665daab3`.

Command:

```bash
surge build --release benchmarks/state_probe
SURGE_THREADS=1 ./target/release/state_probe
SURGE_THREADS=4 ./target/release/state_probe
SURGE_THREADS=8 ./target/release/state_probe
```

## Results

`SURGE_THREADS=1`:

| probe | iterations | total us | ns/op |
| --- | ---: | ---: | ---: |
| direct_store_get | 50000 | 45554 | 911 |
| direct_store_set | 50000 | 106513 | 2130 |
| direct_apply_get | 50000 | 55657 | 1113 |
| direct_apply_set | 50000 | 120425 | 2408 |
| manager_get_reused_reply | 50000 | 263542 | 5270 |
| manager_set_reused_reply | 50000 | 334623 | 6692 |
| manager_apply_get_reused_reply | 50000 | 268297 | 5365 |
| manager_apply_set_reused_reply | 50000 | 349753 | 6995 |

`SURGE_THREADS=4`:

| probe | iterations | total us | ns/op |
| --- | ---: | ---: | ---: |
| direct_store_get | 50000 | 44344 | 886 |
| direct_store_set | 50000 | 104475 | 2089 |
| direct_apply_get | 50000 | 54279 | 1085 |
| direct_apply_set | 50000 | 119520 | 2390 |
| manager_get_reused_reply | 50000 | 683081 | 13661 |
| manager_set_reused_reply | 50000 | 881438 | 17628 |
| manager_apply_get_reused_reply | 50000 | 728741 | 14574 |
| manager_apply_set_reused_reply | 50000 | 903271 | 18065 |

`SURGE_THREADS=8`:

| probe | iterations | total us | ns/op |
| --- | ---: | ---: | ---: |
| direct_store_get | 50000 | 40676 | 813 |
| direct_store_set | 50000 | 100519 | 2010 |
| direct_apply_get | 50000 | 55312 | 1106 |
| direct_apply_set | 50000 | 119070 | 2381 |
| manager_get_reused_reply | 50000 | 655989 | 13119 |
| manager_set_reused_reply | 50000 | 865001 | 17300 |
| manager_apply_get_reused_reply | 50000 | 744662 | 14893 |
| manager_apply_set_reused_reply | 50000 | 909944 | 18198 |

## Notes

- Direct `Store` reads/writes are microsecond-scale and are not the current
  throughput ceiling.
- The manager channel hop is visible and thread-count sensitive, but it is much
  smaller than the current protocol/shard routing cost.
