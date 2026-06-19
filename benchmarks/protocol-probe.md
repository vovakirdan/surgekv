# surgekv protocol probe

Generated: 2026-06-19

## Environment

- host: Linux DESKTOP-N3J9OLI WSL2
- surge: `/usr/local/bin/surge` `0.1.10-dev` commit `b2abcf2c4360`
- command: `PATH=/usr/local/bin:$PATH surge build --release benchmarks/protocol_probe && ./target/release/protocol_probe`
- iterations per row: `20000`

## Results

| probe | iterations | total us | ns/op |
| --- | ---: | ---: | ---: |
| parse_ping | 20000 | 166198 | 8309 |
| parse_get | 20000 | 470117 | 23505 |
| parse_set | 20000 | 4512700 | 225635 |
| parse_mixed_get_set | 20000 | 2600949 | 130047 |
| format_value | 20000 | 11897 | 594 |
| format_ok_version | 20000 | 28049 | 1402 |
| format_error | 20000 | 15179 | 758 |
| line_bytes_value | 20000 | 498701 | 24935 |

## Notes

- `SET` parsing is the visible protocol-layer outlier because it includes JSON validation.
- `GET` parsing is much cheaper than `SET`, but still larger than the fixed channel hop baseline.
- Response formatting itself is cheap; byte conversion for response lines is the larger response-side cost.
