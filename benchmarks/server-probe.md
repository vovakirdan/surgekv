# surgekv server primitive probe

Generated: 2026-06-19 with Surge `0.1.11-dev` commit `2c06665daab3`.

Command:

```bash
surge build --release benchmarks/server_probe
./target/release/server_probe
```

## Results

| probe | iterations | total us | ns/op |
| --- | ---: | ---: | ---: |
| append_chunk_get | 20000 | 17263 | 863 |
| take_next_line_single | 20000 | 294347 | 14717 |
| take_next_line_pipelined4 | 80000 | 1362826 | 17035 |
| hash_stable64_bucket | 20000 | 7098216 | 354910 |
| hash_xxh64_bucket | 20000 | 3798418 | 189920 |
| hash_cheap_bucket | 20000 | 280386 | 14019 |
| line_bytes_value_server | 20000 | 601988 | 30099 |
| get_pipeline_no_tcp_no_manager | 20000 | 8586383 | 429319 |
| get_pipeline_xxh64_no_tcp_no_manager | 20000 | 5385112 | 269255 |
| get_pipeline_cheap_no_tcp_no_manager | 20000 | 1748737 | 87436 |
| set_pipeline_no_tcp_no_manager | 20000 | 13131028 | 656551 |
| set_pipeline_xxh64_no_tcp_no_manager | 20000 | 11568155 | 578407 |
| set_pipeline_cheap_no_tcp_no_manager | 20000 | 7166762 | 358338 |

## Notes

- This probe copies the current server line/byte hot-path shape so it can run
  outside the production server module.
- `stable64_string` was the previous production shard routing shape.
- `xxh64_string` is a stdlib raw-hash alternative. It is faster than stable
  structured hashing, but still too expensive for per-request routing.
- `hash_cheap_bucket` matches the current production bucket-only routing helper.
