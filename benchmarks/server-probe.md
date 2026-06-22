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
| append_chunk_get | 20000 | 15578 | 778 |
| take_next_line_single | 20000 | 204917 | 10245 |
| take_next_line_pipelined4 | 80000 | 923951 | 11549 |
| hash_cheap_bucket | 20000 | 240085 | 12004 |
| line_bytes_value_server | 20000 | 553165 | 27658 |
| get_pipeline_cheap_no_tcp_no_manager | 20000 | 1346328 | 67316 |
| set_pipeline_cheap_no_tcp_no_manager | 20000 | 3213954 | 160697 |

## Notes

- This probe copies the current server line/byte hot-path shape so it can run
  outside the production server module.
- `hash_cheap_bucket` matches the current production bucket-only routing helper.
- The probe now keeps only production-shaped rows; old stdlib hash comparison
  rows are covered by earlier reports.
