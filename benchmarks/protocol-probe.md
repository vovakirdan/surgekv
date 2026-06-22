# surgekv protocol probe

Generated: 2026-06-22

## Environment

- host: Linux DESKTOP-N3J9OLI WSL2
- surge: `surge` `0.1.12-dev` commit `e7142f04`
- command: `SURGE_STDLIB=/home/zov/projects/surge/surge PATH=/usr/local/bin:$PATH surge build --release benchmarks/protocol_probe && ./target/release/protocol_probe`
- iterations per row: `20000`

## Results

| probe | iterations | total us | ns/op |
| --- | ---: | ---: | ---: |
| parse_ping | 20000 | 120921 | 6046 |
| parse_get | 20000 | 282822 | 14141 |
| parse_set | 20000 | 1522890 | 76144 |
| parse_mixed_get_set | 20000 | 1128658 | 56432 |
| format_value | 20000 | 13430 | 671 |
| format_ok_version | 20000 | 31776 | 1588 |
| format_error | 20000 | 20615 | 1030 |
| line_bytes_value | 20000 | 534221 | 26711 |

## Notes

- `SET` parsing is still higher than `GET`, but fast `json.validate` removed the earlier parse bottleneck.
- `GET` parsing is now around `14us/op`; further protocol gains are likely smaller than TCP/runtime work.
- Response formatting itself is cheap; byte conversion for response lines is the larger response-side cost.
