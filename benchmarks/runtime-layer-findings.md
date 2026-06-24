# surgekv runtime layer findings

Generated: 2026-06-24 with Surge `0.1.13-dev` commit `08c5fef`.

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
- `benchmarks/tcp-pipeline-probe.md`
- `benchmarks/research-pipeline-threads1.md`
- `benchmarks/research-pipeline-threads8.md`
- `benchmarks/research-batchwrite-threads1.md`
- `benchmarks/research-batchwrite-threads8.md`
- `benchmarks/manager-path-probe.md`
- `benchmarks/research-append-string-response.md`
- `benchmarks/research-next-layer-threads1.md`
- `benchmarks/research-next-layer-threads8.md`
- `benchmarks/research-byte-numeric-parser.md`

## Short conclusion

The current ceiling is not the KV map, not shard routing, no longer JSON
validation, and no longer response byte assembly.

The large confirmed wins are done:

- Shard routing moved off `hash.stable64_string(...).bucket(...)` and now uses
  a local bucket-only helper. The server primitive route probe is about
  `12us/op`.
- `surgekv` now calls `json.validate` instead of `json.parse` in `ensure_json`.
  On the current compiler/stdlib, object validation is about `3.4us/op` instead
  of full parse at about `149us/op`.
- `append_line_bytes` now uses `Array<byte>.append_string`, the stdlib bulk-copy
  helper. `line_bytes_value_server` moved from the previous `~28us/op` range to
  `~1.5us/op`.
- The input side now uses `stdlib/bytes.ByteBuffer`, and numeric protocol
  fields in `SET ... IF` plus `OWN/BORROW ... TTL` use
  `bytes.next_uint64_ascii_token`. The protocol-only numeric rows improve by
  about `1.36-1.44x`. Full TCP `SET IF` improves by about `4-16%` in the short
  local matrix. TTL lease commands barely move, so their bottleneck is not
  numeric token parsing.

The socket response-write hypothesis is confirmed for pipelined clients.
Batching already-buffered responses lifts `ping_pipe` to `72-82k rps` and drops
a 20000-request strace sample from about `20005` writes to `133`.

Roundtrip rows move less than pipeline rows. The in-process server pipeline is
now about `44us` for GET without a manager hop, about `51us` for GET with the
real manager task on `SURGE_THREADS=1`, and about `173us` for SET without a
manager hop. Splitting GET shows response byte assembly is cheap after
`append_string`; the remaining visible local GET costs are mostly line
buffering (`~11-16us`), `GET` parsing (`~15-22us`), bucket routing (`~12.8us`),
and the manager channel hop (`~4.8us` on one runtime thread, `~11-12us` on
4/8 runtime threads).
The `WHOAMI` probe confirms all-shard manager fanout is expensive, but GET is
still much closer to the parser/response path than to all-shard fanout.

Full TCP GET still does not scale like Redis or Valkey. In the 2026-06-23
next-layer run, `SURGE_THREADS=1` reached `3096 rps` for single-client GET
with `322us` average latency, while single-client PING was already close to
Redis (`97us` vs `94us`). The full in-process GET path is only `~51us`, so the
remaining single-client gap is mostly in the live socket/task path around the
real connection, not the KV map. `SURGE_THREADS=8` worsened non-pipelined PING
and GET, which keeps executor scheduling and cross-thread task handoff as the
next runtime suspect.

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
| `parse_ping` | 6377 |
| `parse_get` | 21869 |
| `parse_set` | 80654 |
| `parse_mixed_get_set` | 52155 |
| `line_bytes_value` | 1477 |

Byte numeric parser probe, 20000 iterations:

| probe | string parser ns/op | byte parser ns/op | speedup |
| --- | ---: | ---: | ---: |
| `SET ... IF` | 45,208 | 31,581 | 1.43x |
| `OWN ... TTL` | 33,613 | 23,398 | 1.44x |
| `BORROW ... TTL` | 35,407 | 25,950 | 1.36x |

Server primitive rows:

| probe | ns/op |
| --- | ---: |
| `take_next_line_single` | 10960 |
| `take_next_line_pipelined4` | 15907 |
| `parse_get_server` | 16141 |
| bucket-only routing helper | 12755 |
| `format_value_server` | 681 |
| `bytes_view_len_value` | 715 |
| `byte_array_push_constant` | 25580 |
| `line_bytes_value_server` | 1430 |
| `line_bytes_to_array_server` | 1028 |
| direct `VALUE` bytes | 1531 |
| GET pipeline, bucket helper, no TCP/manager | 44130 |
| GET pipeline, direct response bytes | 43595 |
| GET pipeline, real manager, no TCP | 51228 |
| SET pipeline, bucket helper, no TCP/manager | 172659 |

State and manager rows:

| mode | direct GET ns/op | direct SET ns/op | manager GET ns/op | manager SET ns/op |
| --- | ---: | ---: | ---: | ---: |
| `SURGE_THREADS=1` | 762 | 1956 | 4760 | 6281 |
| `SURGE_THREADS=4` | 767 | 1949 | 11931 | 15244 |
| `SURGE_THREADS=8` | 846 | 2016 | 11663 | 15048 |

TCP rows after the JSON validate fix, 5000 requests per row, 32 clients:

| mode | PING rps | GET rps | SET rps | mixed rps | GET p50 us | SET p50 us | errors |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `SURGE_THREADS=1` | 29132 | 5132 | 2757 | 3228 | 4548 | 7825 | 0 |
| `SURGE_THREADS=8` | 10187 | 5594 | 4894 | 3967 | 5099 | 5928 | 0 |
| Redis, same 8-thread run | 71259 | 70922 | 74585 | 73285 | 158 | 160 | 0 |
| Valkey, same 8-thread run | 74981 | 67709 | 74437 | 70098 | 159 | 167 | 0 |

TCP GET rows after the append-string response patch, 5000 requests per row:

| target | clients | GET rps | avg us | p50 us | p95 us | errors |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| surgekv | 1 | 3412 | 292 | 287 | 364 | 0 |
| surgekv | 8 | 3003 | 2644 | 2486 | 5086 | 0 |
| surgekv | 32 | 5397 | 5553 | 4849 | 11045 | 0 |
| Redis | 1 | 10445 | 95 | 92 | 131 | 0 |
| Redis | 8 | 52134 | 149 | 132 | 300 | 0 |
| Redis | 32 | 68751 | 376 | 168 | 980 | 0 |
| Valkey | 1 | 10430 | 95 | 90 | 138 | 0 |
| Valkey | 8 | 49697 | 156 | 138 | 315 | 0 |
| Valkey | 32 | 63985 | 402 | 164 | 1210 | 0 |

Focused TCP rows for the next layer, 5000 requests per row:

| mode | op | clients | surgekv rps | avg us | p50 us | errors |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| `SURGE_THREADS=1` | ping | 1 | 10153 | 97 | 89 | 0 |
| `SURGE_THREADS=1` | get | 1 | 3096 | 322 | 314 | 0 |
| `SURGE_THREADS=1` | get_pipe | 1 | 3796 | 263 | 263 | 0 |
| `SURGE_THREADS=1` | ping | 32 | 23508 | 1098 | 1022 | 0 |
| `SURGE_THREADS=1` | get | 32 | 4612 | 6013 | 6089 | 0 |
| `SURGE_THREADS=1` | get_pipe | 32 | 7348 | 3883 | 4131 | 0 |
| `SURGE_THREADS=8` | ping | 1 | 4425 | 225 | 224 | 0 |
| `SURGE_THREADS=8` | get | 1 | 2476 | 403 | 393 | 0 |
| `SURGE_THREADS=8` | get_pipe | 1 | 3671 | 272 | 272 | 0 |
| `SURGE_THREADS=8` | ping | 32 | 9329 | 2338 | 695 | 0 |
| `SURGE_THREADS=8` | get | 32 | 5241 | 5884 | 5267 | 0 |
| `SURGE_THREADS=8` | get_pipe | 32 | 8386 | 3578 | 3641 | 0 |

Focused TCP rows after the byte input buffer and byte numeric parser patch,
5000 requests per row, 5000 keys, 64-byte values:

| op | clients | before rps | after rps | before avg us | after avg us | errors |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `setif` | 1 | 2420 | 2816 | 412 | 354 | 0 |
| `setif` | 8 | 5233 | 5458 | 1476 | 1415 | 0 |
| `setif` | 32 | 5759 | 6366 | 4985 | 4547 | 0 |
| `own_ttl` | 1 | 640 | 672 | 1560 | 1487 | 0 |
| `own_ttl` | 8 | 2511 | 2534 | 3117 | 3081 | 0 |
| `own_ttl` | 32 | 2959 | 2836 | 9971 | 10396 | 0 |
| `borrow_ttl` | 1 | 646 | 649 | 1546 | 1539 | 0 |
| `borrow_ttl` | 8 | 2494 | 2559 | 3139 | 3051 | 0 |
| `borrow_ttl` | 32 | 2802 | 2931 | 10492 | 9935 | 0 |

TCP rows before the JSON validate fix, after the hash fix:

| mode | GET rps | SET rps | mixed rps |
| --- | ---: | ---: | ---: |
| `SURGE_THREADS=1` | 3943 | 1382 | 2007 |
| `SURGE_THREADS=8` | 5344 | 2532 | 3117 |

TCP pipelined rows, 5000 requests per row, 32 clients:

| mode | PING pipe rps | GET pipe rps | SET pipe rps | mixed pipe rps |
| --- | ---: | ---: | ---: | ---: |
| `SURGE_THREADS=1`, before batch writes | 38358 | 4519 | 2861 | 2379 |
| `SURGE_THREADS=1`, after batch writes | 72025 | 8982 | 3964 | 5380 |
| `SURGE_THREADS=8`, before batch writes | 21851 | 8130 | 5323 | 5986 |
| `SURGE_THREADS=8`, after batch writes | 81806 | 10191 | 5737 | 7370 |
| Redis, same 8-thread run | 1740219 | 1180159 | 946484 | 1245941 |
| Valkey, same 8-thread run | 1794051 | 1220881 | 1092465 | 996828 |

## Next Work

`surgekv` work:

- Keep the `json.validate` wrapper and the local bucket helper.
- Keep `append_line_bytes` on `Array<byte>.append_string`; manual `byte[].push`
  loops are still slow.
- Keep response batching in `serve_client`; it confirms the pipelined socket
  write hypothesis.
- Keep the byte input buffer and byte numeric parser. Broader parser/tokenizer
  work can still recover tens of microseconds locally, but issue #4 confirms it
  cannot explain the current single-client TCP GET gap by itself.
- Investigate `OWN/BORROW TTL` separately: after the numeric parser patch, TTL
  traffic still sits near `650 rps` for one client, so lease mutation,
  expiry-record maintenance, or manager/task interaction is the likely layer.
- Do not prioritize `net.write_all_string` until a new TCP-specific trace shows
  write-side cost again. The cheap response byte path is already in place.
- Add long-run RSS/heap sampling once the short path stops moving quickly.

Surge / runtime work:

- Investigate live TCP task scheduling around `net.read_some`,
  `net.write_all`, and channel handoff between socket tasks and manager tasks.
  `PING` proves the single-client socket baseline can be good on one runtime
  thread, while `GET` is still far above the in-process manager pipeline.
- Investigate why `SURGE_THREADS=8` hurts non-pipelined PING/GET latency and
  why manager hops are about `2.4x` slower than `SURGE_THREADS=1`.
- Track stdlib hash follow-up in `vovakirdan/surge#144`; `surgekv` still has a
  local helper as the cheaper route today.
