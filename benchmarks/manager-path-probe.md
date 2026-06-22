# surgekv manager path probe

Generated: 2026-06-22 after `d9b1ca5` with Surge `0.1.12-dev` commit
`e7142f04`.

This probe uses the same release `surgekv` binary and extends the local Go
loadgen with `whoami` / `whoami_pipe`. No server protocol changes are required:
`WHOAMI` already exists.

## Results

32-client rows, 5000 requests per row:

| mode | op | rps | avg us | p50 us | p95 us | p99 us |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| `SURGE_THREADS=1` | ping | 25423 | 1067 | 1011 | 1181 | 1648 |
| `SURGE_THREADS=1` | ping_pipe | 71339 | 238 | 224 | 445 | 446 |
| `SURGE_THREADS=1` | whoami | 4197 | 7557 | 6983 | 9665 | 10037 |
| `SURGE_THREADS=1` | whoami_pipe | 4829 | 5733 | 5624 | 6629 | 6630 |
| `SURGE_THREADS=1` | get | 6019 | 4442 | 4271 | 4691 | 5190 |
| `SURGE_THREADS=1` | get_pipe | 8703 | 3068 | 3088 | 3655 | 3673 |
| `SURGE_THREADS=8` | ping | 11238 | 1878 | 610 | 1500 | 11232 |
| `SURGE_THREADS=8` | ping_pipe | 77113 | 252 | 268 | 404 | 408 |
| `SURGE_THREADS=8` | whoami | 2341 | 13174 | 11368 | 27237 | 43819 |
| `SURGE_THREADS=8` | whoami_pipe | 2525 | 12269 | 12373 | 12666 | 12687 |
| `SURGE_THREADS=8` | get | 6223 | 4954 | 4507 | 9727 | 13789 |
| `SURGE_THREADS=8` | get_pipe | 9970 | 3062 | 3099 | 3198 | 3206 |

## Reading

- `WHOAMI` fans out to every shard and is visibly expensive, especially on
  `SURGE_THREADS=8`. That matters for admin commands, not for the hot GET/SET
  path.
- `GET` is much slower than `PING`, but not as slow as all-shard `WHOAMI`.
  Together with `server_probe`, this points back at protocol/response work:
  `parse_get`, bucket routing, and string-to-byte response serialization.
- The next local target should be response serialization and parser/tokenizer
  cost, not a larger manager redesign.
