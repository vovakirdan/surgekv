# surgekv runtime layer findings

Generated: 2026-06-19 with Surge `0.1.11-dev` commit `2c06665daab3`.

Source reports:

- `benchmarks/state-probe.md`
- `benchmarks/server-probe.md`
- `benchmarks/research-local-threads1.md`
- `benchmarks/research-local-threads8.md`
- `benchmarks/research-hashfix-threads1.md`
- `benchmarks/research-hashfix-threads8.md`
- `benchmarks/protocol-probe.md`

## Short conclusion

The current ceiling is not the KV map and not memory growth.

The largest confirmed `surgekv` hot-path issue was shard routing: every key
command called `hash.stable64_string(key).bucket(shard_count)`. The local
bucket-only helper replaces that in production now. In the server primitive
probe, routing dropped from about `355us/op` to about `14us/op`, and the GET
pipeline without TCP/manager dropped from about `429us/op` to about `87us/op`.

The next confirmed `surgekv`/stdlib boundary issue is JSON validation. `SET`
parse still costs about `269us/op`; the full SET pipeline with cheap routing
is still about `358us/op` in the latest local run.

The Surge runtime is still relevant, but it is no longer the only explanation:
the manager request/reply hop is about `5-7us/op` on `SURGE_THREADS=1` and
about `13-18us/op` on 4-8 threads. That is visible, but smaller than routing
and JSON parse in the current stateful path.

## Evidence

TCP rows before the routing fix, 5000 requests per row, 32 clients:

| mode | PING rps | GET rps | SET rps | mixed rps | GET p50 us | SET p50 us | errors |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `SURGE_THREADS=1` | 19714 | 1709 | 1038 | 1219 | 9713 | 24709 | 0 |
| `SURGE_THREADS=8` | 9642 | 2581 | 1551 | 1894 | 11723 | 19641 | 0 |
| Redis, same 8-thread run | 66422 | 70587 | 69647 | 66637 | 177 | 172 | 0 |
| Valkey, same 8-thread run | 71734 | 68861 | 70272 | 65032 | 188 | 186 | 0 |

TCP rows after the routing fix, 5000 requests per row, 32 clients:

| mode | PING rps | GET rps | SET rps | mixed rps | GET p50 us | SET p50 us | errors |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `SURGE_THREADS=1` | 21906 | 3943 | 1382 | 2007 | 4330 | 10763 | 0 |
| `SURGE_THREADS=8` | 10745 | 5344 | 2532 | 3117 | 5436 | 11770 | 0 |
| Redis, same 8-thread run | 77505 | 61676 | 70812 | 62221 | 173 | 181 | 0 |
| Valkey, same 8-thread run | 54034 | 70915 | 63536 | 65357 | 176 | 189 | 0 |

State and manager rows:

| mode | direct GET ns/op | direct SET ns/op | manager GET ns/op | manager SET ns/op |
| --- | ---: | ---: | ---: | ---: |
| `SURGE_THREADS=1` | 911 | 2130 | 5270 | 6692 |
| `SURGE_THREADS=4` | 886 | 2089 | 13661 | 17628 |
| `SURGE_THREADS=8` | 813 | 2010 | 13119 | 17300 |

Server primitive rows:

| probe | ns/op |
| --- | ---: |
| `take_next_line_single` | 14830 |
| `hash.stable64_string(...).bucket(8)` | 354910 |
| `hash.xxh64_string(...).bucket(8)` | 189920 |
| bucket-only routing helper | 14019 |
| `line_bytes_value_server` | 30099 |
| GET pipeline, stable hash, no TCP/manager | 429319 |
| GET pipeline, bucket helper, no TCP/manager | 87436 |
| SET pipeline, stable hash, no TCP/manager | 656551 |
| SET pipeline, bucket helper, no TCP/manager | 358338 |

Protocol rows:

| probe | ns/op |
| --- | ---: |
| `parse_get` | 27694 |
| `parse_set` | 268932 |
| `parse_mixed_get_set` | 151202 |
| `line_bytes_value` | 31638 |

## Ownership split

`surgekv` work:

- Keep `state_probe` and `server_probe` as benchmark guards for future hot-path
  work.
- Optimize or redesign line buffering after the routing fix. Current
  `take_next_line` clones the whole buffer and rebuilds the remainder for every
  line.
- Treat JSON validation as a separate library/API task. For v1 protocol safety
  it is correct to validate JSON, but the current parser cost dominates `SET`.

Surge / stdlib / runtime work:

- Investigate why stdlib `hash.xxh64_string` and especially
  `hash.stable64_string` are so expensive for short strings. `stable64` may be
  semantically correct but is not suitable for per-request routing at this
  cost.
- Consider a stdlib `bucket_string(text, bucket_count)` or faster raw hash path
  for routing use cases. `surgekv` currently carries a local helper as a
  workaround. Tracked upstream as `vovakirdan/surge#144`.
- Continue net/task runtime profiling after the routing fix. `PING` is much
  closer to Redis/Valkey than stateful rows, but multi-thread p95/p99 tails and
  the residual TCP gap still need runtime evidence.
