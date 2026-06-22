# surgekv JSON probe

Generated: 2026-06-22 with Surge `0.1.12-dev` commit `e7142f04`.

Command:

```bash
SURGE_STDLIB=/home/zov/projects/surge/surge \
PATH=/usr/local/bin:$PATH \
surge build --release benchmarks/json_probe

./target/release/json_probe
```

## Results

| probe | iterations | total us | ns/op |
| --- | ---: | ---: | ---: |
| parse_scalar | 20000 | 295417 | 14770 |
| validate_scalar | 20000 | 28776 | 1438 |
| parse_object | 20000 | 2971533 | 148576 |
| validate_object | 20000 | 68248 | 3412 |
| parse_nested | 20000 | 11890593 | 594529 |
| validate_nested | 20000 | 328159 | 16407 |

## Notes

- `surgekv` stores JSON values as strings, so validate-only is the right hot
  path.
- The current stdlib `json.validate` is now materially faster than full parse.
