# surgekv protocol probe

Generated: 2026-06-19

## Environment

- host: Linux DESKTOP-N3J9OLI WSL2
- surge: `surge` `0.1.11-dev` commit `2c06665daab3`
- command: `surge build --release benchmarks/protocol_probe && ./target/release/protocol_probe`
- iterations per row: `20000`

## Results

| probe | iterations | total us | ns/op |
| --- | ---: | ---: | ---: |
| parse_ping | 20000 | 195552 | 9777 |
| parse_get | 20000 | 536806 | 26840 |
| parse_set | 20000 | 5378020 | 268901 |
| parse_mixed_get_set | 20000 | 2988554 | 149427 |
| format_value | 20000 | 14511 | 725 |
| format_ok_version | 20000 | 34077 | 1703 |
| format_error | 20000 | 17845 | 892 |
| line_bytes_value | 20000 | 608681 | 30434 |

## Notes

- `SET` parsing is the visible protocol-layer outlier because it includes JSON validation.
- `GET` parsing is much cheaper than `SET`, but still larger than the fixed channel hop baseline.
- Response formatting itself is cheap; byte conversion for response lines is the larger response-side cost.
