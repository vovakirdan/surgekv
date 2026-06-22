# surgekv runtime layer findings

Generated: 2026-06-22 with Surge `0.1.12-dev` commit `e7142f04`.

Important benchmark builds used `SURGE_STDLIB=/home/zov/projects/surge/surge`
so the fresh compiler used the matching checkout stdlib.

Source reports:

- `benchmarks/json-probe.md`
- `benchmarks/protocol-probe.md`
- `benchmarks/server-probe.md`
- `benchmarks/state-probe.md`
- `benchmarks/research-hashfix-threads1.md`
- `benchmarks/research-hashfix-threads8.md`
- `benchmarks/research-jsonvalidate-threads1.md`
- `benchmarks/research-jsonvalidate-threads8.md`

## Short conclusion

The current ceiling is not the KV map, not shard routing, and no longer JSON
validation.

The two large confirmed wins are done:

- Shard routing moved off `hash.stable64_string(...).bucket(...)` and now uses
  a local bucket-only helper. The server primitive route probe is about
  `12us/op`.
- `surgekv` now calls `json.validate` instead of `json.parse` in `ensure_json`.
  On the current compiler/stdlib, object validation is about `3.4us/op` instead
  of full parse at about `149us/op`.

The next bottleneck is the full TCP/runtime path. The in-process server
pipeline is now about `69us` for GET and `166us` for SET, while 32-client TCP
p50 latency is still several milliseconds. That gap is larger than the current
protocol, JSON, state, and manager micro costs.

## Evidence

JSON probe, 20000 iterations:

| probe | ns/op |
| --- | ---: |
| `parse_scalar` | 14770 |
| `validate_scalar` | 1438 |
| `parse_object` | 148576 |
| `validate_object` | 3412 |
| `parse_nested` | 594529 |
| `validate_nested` | 16407 |

Protocol probe, 20000 iterations:

| probe | ns/op |
| --- | ---: |
| `parse_ping` | 6046 |
| `parse_get` | 14141 |
| `parse_set` | 76144 |
| `parse_mixed_get_set` | 56432 |
| `line_bytes_value` | 26711 |

Server primitive rows:

| probe | ns/op |
| --- | ---: |
| `take_next_line_single` | 10331 |
| `take_next_line_pipelined4` | 11408 |
| bucket-only routing helper | 12030 |
| `line_bytes_value_server` | 27358 |
| GET pipeline, bucket helper, no TCP/manager | 68696 |
| SET pipeline, bucket helper, no TCP/manager | 165776 |

State and manager rows from the previous probe:

| mode | direct GET ns/op | direct SET ns/op | manager GET ns/op | manager SET ns/op |
| --- | ---: | ---: | ---: | ---: |
| `SURGE_THREADS=1` | 911 | 2130 | 5270 | 6692 |
| `SURGE_THREADS=4` | 886 | 2089 | 13661 | 17628 |
| `SURGE_THREADS=8` | 813 | 2010 | 13119 | 17300 |

TCP rows after the JSON validate fix, 5000 requests per row, 32 clients:

| mode | PING rps | GET rps | SET rps | mixed rps | GET p50 us | SET p50 us | errors |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `SURGE_THREADS=1` | 29132 | 5132 | 2757 | 3228 | 4548 | 7825 | 0 |
| `SURGE_THREADS=8` | 10187 | 5594 | 4894 | 3967 | 5099 | 5928 | 0 |
| Redis, same 8-thread run | 71259 | 70922 | 74585 | 73285 | 158 | 160 | 0 |
| Valkey, same 8-thread run | 74981 | 67709 | 74437 | 70098 | 159 | 167 | 0 |

TCP rows before the JSON validate fix, after the hash fix:

| mode | GET rps | SET rps | mixed rps |
| --- | ---: | ---: | ---: |
| `SURGE_THREADS=1` | 3943 | 1382 | 2007 |
| `SURGE_THREADS=8` | 5344 | 2532 | 3117 |

## Next Work

`surgekv` work:

- Keep the `json.validate` wrapper and the local bucket helper.
- Do not spend much more time on line-buffer or response-byte micro-tweaks yet;
  they are around `10-27us/op`, while TCP p50 is still measured in
  milliseconds at 32 clients.
- Add a minimal TCP server-path probe if needed: PING-only, parse-only, and
  parse+write rows without manager state.
- Add long-run RSS/heap sampling once the short path stops moving quickly.

Surge / runtime work:

- Investigate multi-worker TCP scheduling and tail latency. `SURGE_THREADS=8`
  improves SET throughput but hurts PING throughput versus one thread.
- Keep an eye on channel hop cost, but it is not the largest known number after
  the JSON fix.
- Track stdlib hash follow-up in `vovakirdan/surge#144`; `surgekv` still has a
  local helper as the cheaper route today.
