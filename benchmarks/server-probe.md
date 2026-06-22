# surgekv server primitive probe

Generated: 2026-06-22 with Surge `0.1.12-dev` commit `e7142f04`.

Command:

```bash
SURGE_STDLIB=/home/zov/projects/surge/surge \
PATH=/usr/local/bin:$PATH \
surge build --release benchmarks/server_probe
./target/release/server_probe
```

## Results

| probe | iterations | total us | ns/op |
| --- | ---: | ---: | ---: |
| append_chunk_get | 20000 | 15495 | 774 |
| take_next_line_single | 20000 | 206637 | 10331 |
| take_next_line_pipelined4 | 80000 | 912642 | 11408 |
| hash_cheap_bucket | 20000 | 240615 | 12030 |
| line_bytes_value_server | 20000 | 547177 | 27358 |
| get_pipeline_cheap_no_tcp_no_manager | 20000 | 1373924 | 68696 |
| set_pipeline_cheap_no_tcp_no_manager | 20000 | 3315526 | 165776 |

## Notes

- This probe copies the current server line/byte hot-path shape so it can run
  outside the production server module.
- `hash_cheap_bucket` matches the current production bucket-only routing helper.
- The probe now keeps only production-shaped rows; old stdlib hash comparison
  rows are covered by earlier reports.
