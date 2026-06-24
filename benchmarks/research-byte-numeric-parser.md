# Byte numeric parser research

Generated: 2026-06-24 with Surge `0.1.13-dev` commit `08c5fef29bed`.

Context: `vovakirdan/surgekv#4` suggested using the new
`stdlib/bytes.next_uint64_ascii_token` helper for numeric protocol fields.

Builds used `SURGE_STDLIB=/home/zov/projects/surge/surge` so the compiler and
stdlib came from the same fresh checkout.

## What changed

- `server` now keeps the socket input buffer as `stdlib/bytes.ByteBuffer`
  instead of repeatedly converting read chunks into a concatenated `string`.
- `proto.parse_line_bytes` handles `SET ... IF <version>` and
  `OWN/BORROW ... TTL <seconds>` on byte ranges.
- Other commands still fall back to the existing string parser to keep this
  patch narrow.
- `scripts/bench_load.go` can now generate `setif`, `own_ttl`, and
  `borrow_ttl` workloads for SurgeKV.

## Protocol probe

20,000 iterations. The old rows are the existing string parser. The `*_bytes`
rows use `parse_line_bytes` over a prebuilt `byte[]`.

| probe | old ns/op | byte ns/op | speedup |
| --- | ---: | ---: | ---: |
| `SET ... IF` | 45,208 | 31,581 | 1.43x |
| `OWN ... TTL` | 33,613 | 23,398 | 1.44x |
| `BORROW ... TTL` | 35,407 | 25,950 | 1.36x |

The byte helper helps, but the real protocol parser still has to materialize
owned key/value strings and validate JSON. This is why the huge isolated Surge
microbenchmark from the upstream issue does not translate directly into a huge
surgekv speedup.

## Full TCP numeric rows

Each row used a fresh `surgekv` process, 5,000 requests, 5,000 keys, 64-byte
JSON values, `workers=8`, `shards=8`, and `expiry-interval-ms=250`.

`keys=requests` is deliberate: each timed command uses a unique key so
`SET IF 1` and lease commands measure parser/server cost rather than version
or lock conflicts.

| op | clients | before rps | after rps | before avg us | after avg us | errors |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `setif` | 1 | 2,420 | 2,816 | 412 | 354 | 0 |
| `setif` | 8 | 5,233 | 5,458 | 1,476 | 1,415 | 0 |
| `setif` | 32 | 5,759 | 6,366 | 4,985 | 4,547 | 0 |
| `own_ttl` | 1 | 640 | 672 | 1,560 | 1,487 | 0 |
| `own_ttl` | 8 | 2,511 | 2,534 | 3,117 | 3,081 | 0 |
| `own_ttl` | 32 | 2,959 | 2,836 | 9,971 | 10,396 | 0 |
| `borrow_ttl` | 1 | 646 | 649 | 1,546 | 1,539 | 0 |
| `borrow_ttl` | 8 | 2,494 | 2,559 | 3,139 | 3,051 | 0 |
| `borrow_ttl` | 32 | 2,802 | 2,931 | 10,492 | 9,935 | 0 |

`SET IF` benefits measurably. TTL lease traffic barely moves, which points at
lease/expiry/state-manager work rather than numeric token parsing.

## Full TCP common rows

Same setup as above. These rows are not numeric-specific; they check whether
the new byte input buffer regressed the usual paths.

| op | clients | before rps | after rps | before avg us | after avg us | errors |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `ping` | 1 | 8,722 | 8,721 | 113 | 113 | 0 |
| `ping` | 8 | 14,266 | 14,237 | 546 | 550 | 0 |
| `ping` | 32 | 25,736 | 24,560 | 1,170 | 1,224 | 0 |
| `get` | 1 | 3,550 | 3,484 | 280 | 286 | 0 |
| `get` | 8 | 5,631 | 5,608 | 1,375 | 1,373 | 0 |
| `get` | 32 | 6,493 | 6,531 | 4,424 | 4,411 | 0 |
| `set` | 1 | 2,205 | 2,729 | 452 | 365 | 0 |
| `set` | 8 | 4,997 | 5,109 | 1,546 | 1,514 | 0 |
| `set` | 32 | 5,449 | 5,809 | 5,329 | 4,925 | 0 |
| `mixed` | 1 | 2,754 | 3,160 | 362 | 315 | 0 |
| `mixed` | 8 | 5,343 | 5,483 | 1,446 | 1,394 | 0 |
| `mixed` | 32 | 6,139 | 6,330 | 4,647 | 4,510 | 0 |

The common path did not regress materially. `SET` and `mixed` improve because
the socket input path no longer appends chunks through string concatenation.

## Conclusion

The issue #4 helper is worth using, especially for `SET IF`, but it is not the
main remaining ceiling. The next visible downstream target is TTL lease cost:
`OWN/BORROW TTL` stay around `650 rps` for one client even after byte numeric
parsing, so their cost is likely in lease mutation, expiry-record maintenance,
or manager/task interaction.
