# surgekv server primitive probe

Generated: 2026-06-23 with Surge `0.1.12-dev` commit `5c4a0db`.

Command:

```bash
SURGE_STDLIB=/home/zov/projects/surge/surge \
/home/zov/projects/surge/surge/surge build --release benchmarks/server_probe
SURGE_THREADS=1 ./target/release/server_probe
```

## Results

| probe | iterations | total us | ns/op |
| --- | ---: | ---: | ---: |
| append_chunk_get | 20000 | 16134 | 806 |
| take_next_line_single | 20000 | 219210 | 10960 |
| take_next_line_pipelined4 | 80000 | 1272633 | 15907 |
| parse_get_server | 20000 | 322828 | 16141 |
| hash_cheap_bucket | 20000 | 255102 | 12755 |
| format_value_server | 20000 | 13633 | 681 |
| line_bytes_value_server | 20000 | 28615 | 1430 |
| line_bytes_to_array_server | 20000 | 20563 | 1028 |
| byte_array_push_constant | 20000 | 511617 | 25580 |
| bytes_view_len_value | 20000 | 14319 | 715 |
| value_line_bytes_manual_string | 20000 | 31666 | 1583 |
| value_line_bytes_direct | 20000 | 30626 | 1531 |
| get_pipeline_cheap_no_tcp_no_manager | 20000 | 882617 | 44130 |
| get_pipeline_cheap_direct_response | 20000 | 871900 | 43595 |
| get_pipeline_manager_no_tcp | 20000 | 1024569 | 51228 |
| set_pipeline_cheap_no_tcp_no_manager | 20000 | 3453184 | 172659 |

## Notes

- This probe copies the current server line/byte hot-path shape so it can run
  outside the production server module.
- `hash_cheap_bucket` matches the current production bucket-only routing helper.
- `append_line_bytes` now uses `Array<byte>.append_string`, matching production.
  This moves `line_bytes_value_server` from the previous `~28us/op` range to
  `~1.5us/op`.
- Manual byte-by-byte push remains expensive (`byte_array_push_constant` is
  still `~25us/op`), so production code should stay on the stdlib bulk-copy
  helper.
- The GET no-TCP/no-manager probe moved from `~68us/op` to `~44us/op`; the
  remaining GET-side costs are now mostly parser, line buffering, and routing
  helper work.
- Adding the real manager task but still no TCP lands at `~51us/op` on
  `SURGE_THREADS=1`. This is far below live TCP GET latency, so the next gap is
  outside the KV map and mostly outside the local parser/manager path.
- The probe now keeps only production-shaped rows; old stdlib hash comparison
  rows are covered by earlier reports.
