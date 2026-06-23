# surgekv protocol probe

Generated: 2026-06-23

## Environment

- host: Linux DESKTOP-N3J9OLI WSL2
- surge: `surge` `0.1.12-dev` commit `5c4a0db`
- command: `SURGE_STDLIB=/home/zov/projects/surge/surge /home/zov/projects/surge/surge/surge build --release benchmarks/protocol_probe && ./target/release/protocol_probe`
- iterations per row: `20000`

## Results

| probe | iterations | total us | ns/op |
| --- | ---: | ---: | ---: |
| parse_ping | 20000 | 127559 | 6377 |
| parse_get | 20000 | 437396 | 21869 |
| parse_set | 20000 | 1613093 | 80654 |
| parse_mixed_get_set | 20000 | 1043113 | 52155 |
| format_value | 20000 | 14324 | 716 |
| format_ok_version | 20000 | 33418 | 1670 |
| format_error | 20000 | 17624 | 881 |
| line_bytes_value | 20000 | 29547 | 1477 |

## Notes

- `SET` parsing is still higher than `GET`, mostly from command tokenization and
  payload validation work.
- `GET` parsing is around `15-22us/op`; this is now larger than response byte
  assembly.
- Response formatting and byte assembly are both cheap after
  `Array<byte>.append_string`; `line_bytes_value` is about `1.5us/op`.
