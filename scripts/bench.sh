#!/usr/bin/env bash
set -euo pipefail

HOST="${SURGEKV_BENCH_HOST:-127.0.0.1}"
PORT="${1:-${SURGEKV_BENCH_PORT:-$((24000 + RANDOM % 20000))}}"
REDIS_PORT="${SURGEKV_BENCH_REDIS_PORT:-$((PORT + 1))}"
VALKEY_PORT="${SURGEKV_BENCH_VALKEY_PORT:-$((PORT + 2))}"
BIN="${SURGEKV_BIN:-./target/debug/surgekv}"
REQUESTS="${SURGEKV_BENCH_REQUESTS:-200}"
KEYS="${SURGEKV_BENCH_KEYS:-50}"
VALUE_BYTES="${SURGEKV_BENCH_VALUE_BYTES:-64}"
CLIENTS="${SURGEKV_BENCH_CLIENTS:-1 8 32}"
OPS="${SURGEKV_BENCH_OPS:-ping get set mixed}"
WORKERS="${SURGEKV_BENCH_WORKERS:-8}"
SHARDS="${SURGEKV_BENCH_SHARDS:-8}"
MAX_CLIENTS="${SURGEKV_BENCH_MAX_CLIENTS:-0}"
TIMEOUT="${SURGEKV_BENCH_TIMEOUT:-5s}"
BUILD="${SURGEKV_BENCH_BUILD:-1}"
REPORT="${SURGEKV_BENCH_REPORT:-benchmarks/latest-local.md}"

tmp_dir="$(mktemp -d)"
loadgen="$tmp_dir/bench_load"
surge_log="$tmp_dir/surgekv.log"
redis_log="$tmp_dir/redis.log"
valkey_log="$tmp_dir/valkey.log"
surge_pid=""
redis_pid=""
valkey_pid=""

fail() {
    echo "FAIL: $*" >&2
    print_logs
    exit 1
}

print_logs() {
    for path in "$surge_log" "$redis_log" "$valkey_log"; do
        if [[ -s "$path" ]]; then
            echo "--- ${path##*/} ---" >&2
            tail -n 80 "$path" >&2 || true
        fi
    done
}

cleanup() {
    set +e
    for pid in "$surge_pid" "$redis_pid" "$valkey_pid"; do
        if [[ -n "$pid" ]]; then
            kill "$pid" 2>/dev/null
            wait "$pid" 2>/dev/null
        fi
    done
    rm -rf "$tmp_dir"
}
trap cleanup EXIT

require_tool() {
    local name="$1"
    command -v "$name" >/dev/null 2>&1 || fail "missing required tool: $name"
}

wait_for_target() {
    local target="$1"
    local port="$2"
    local i=0
    while [[ "$i" -lt 80 ]]; do
        if "$loadgen" -target "$target" -host "$HOST" -port "$port" -op ping -clients 1 -requests 1 -keys 1 -value-bytes "$VALUE_BYTES" -timeout "$TIMEOUT" -prepare=false >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.1
        i=$((i + 1))
    done
    return 1
}

start_surgekv() {
    "$BIN" \
        --port "$PORT" \
        --workers "$WORKERS" \
        --shards "$SHARDS" \
        --max-clients "$MAX_CLIENTS" \
        --expiry-interval-ms 250 \
        >"$surge_log" 2>&1 &
    surge_pid="$!"
    wait_for_target surgekv "$PORT" || fail "surgekv did not answer on ${HOST}:${PORT}"
}

start_redis() {
    if ! command -v redis-server >/dev/null 2>&1; then
        return 1
    fi
    redis-server \
        --bind "$HOST" \
        --port "$REDIS_PORT" \
        --save "" \
        --appendonly no \
        --protected-mode no \
        >"$redis_log" 2>&1 &
    redis_pid="$!"
    wait_for_target redis "$REDIS_PORT" || fail "redis-server did not answer on ${HOST}:${REDIS_PORT}"
}

start_valkey() {
    if ! command -v valkey-server >/dev/null 2>&1; then
        return 1
    fi
    valkey-server \
        --bind "$HOST" \
        --port "$VALKEY_PORT" \
        --save "" \
        --appendonly no \
        --protected-mode no \
        >"$valkey_log" 2>&1 &
    valkey_pid="$!"
    wait_for_target valkey "$VALKEY_PORT" || fail "valkey-server did not answer on ${HOST}:${VALKEY_PORT}"
}

server_version() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf 'not installed'
        return 0
    fi
    "$cmd" --version 2>&1 | head -n 1
}

git_revision() {
    local rev=""
    rev="$(git rev-parse --short HEAD 2>/dev/null || printf 'unknown')"
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        rev="${rev}-dirty"
    fi
    printf '%s' "$rev"
}

target_port() {
    case "$1" in
        surgekv) printf '%s' "$PORT" ;;
        redis) printf '%s' "$REDIS_PORT" ;;
        valkey) printf '%s' "$VALKEY_PORT" ;;
        *) fail "unknown target: $1" ;;
    esac
}

run_row() {
    local target="$1"
    local op="$2"
    local clients="$3"
    local port=""
    port="$(target_port "$target")"
    "$loadgen" \
        -target "$target" \
        -host "$HOST" \
        -port "$port" \
        -op "$op" \
        -clients "$clients" \
        -requests "$REQUESTS" \
        -keys "$KEYS" \
        -value-bytes "$VALUE_BYTES" \
        -timeout "$TIMEOUT" \
        -format markdown
}

write_failure_row() {
    local target="$1"
    local op="$2"
    local clients="$3"
    printf '| %s | %s | %s | %s | %s | %s | 0 | 0 | 0 | 0 | 0 | %s |\n' \
        "$target" "$op" "$clients" "$REQUESTS" "$KEYS" "$VALUE_BYTES" "$REQUESTS"
}

write_header() {
    local targets="$1"
    mkdir -p "$(dirname "$REPORT")"
    {
        echo "# surgekv local benchmark"
        echo
        echo "Generated: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        echo
        echo "## Environment"
        echo
        echo "- host: $(uname -a)"
        echo "- surge: $(surge version --full | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
        echo "- git: $(git_revision)"
        echo "- go: $(go version)"
        echo "- SURGE_THREADS: ${SURGE_THREADS:-default}"
        echo "- redis-server: $(server_version redis-server)"
        echo "- valkey-server: $(server_version valkey-server)"
        echo
        echo "## Settings"
        echo
        echo "- targets: $targets"
        echo "- requests per row: $REQUESTS"
        echo "- client counts: $CLIENTS"
        echo "- operations: $OPS"
        echo "- keys: $KEYS"
        echo "- value bytes: $VALUE_BYTES"
        echo "- timeout: $TIMEOUT"
        echo "- surgekv: port=$PORT workers=$WORKERS shards=$SHARDS max_clients=$MAX_CLIENTS"
        echo
        echo "## Results"
        echo
        echo "| target | op | clients | requests | keys | value bytes | rps | avg us | p50 us | p95 us | p99 us | errors |"
        echo "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |"
    } >"$REPORT"
}

append_notes() {
    local skipped="$1"
    {
        echo
        echo "## Notes"
        echo
        echo "- The benchmark client uses one persistent TCP connection per logical client."
        echo '- `mixed` alternates SET and GET over the same key space.'
        echo "- The script starts isolated local Redis/Valkey processes only when their server binaries are installed."
        echo "- Rows with non-zero errors are still recorded so partial capacity failures stay visible."
        echo "- Rows with rps/latency set to 0 and errors=requests failed before the timed run, usually during preload."
        if [[ -n "$skipped" ]]; then
            echo "- Skipped targets: $skipped."
        fi
        echo
        echo "## TODO"
        echo
        echo "- Add long soak runs with memory sampling after the short matrix is stable."
        echo '- Add idle-client scaling runs to validate `--max-clients` and task retention behavior.'
        echo "- Add hot-key contention runs with OWN/BORROW/RELEASE traffic."
        echo "- Add disconnect-churn runs to quantify O(entries) cleanup cost."
        echo "- Add TTL churn runs to measure stale expiry-record cleanup."
    } >>"$REPORT"
}

require_tool go
require_tool surge

if [[ "$BUILD" != "0" ]]; then
    surge build .
fi
[[ -x "$BIN" ]] || fail "binary not found or not executable: $BIN"

go build -o "$loadgen" ./scripts/bench_load.go

start_surgekv

targets="surgekv"
skipped=""
if start_redis; then
    targets="$targets redis"
else
    skipped="redis"
fi
if start_valkey; then
    targets="$targets valkey"
else
    if [[ -n "$skipped" ]]; then
        skipped="$skipped, valkey"
    else
        skipped="valkey"
    fi
fi

write_header "$targets"

for target in $targets; do
    for op in $OPS; do
        for clients in $CLIENTS; do
            echo "bench: target=$target op=$op clients=$clients requests=$REQUESTS"
            row_out="$tmp_dir/row-${target}-${op}-${clients}.md"
            if run_row "$target" "$op" "$clients" >"$row_out"; then
                cat "$row_out" >>"$REPORT"
            else
                if [[ -s "$row_out" ]]; then
                    cat "$row_out" >>"$REPORT"
                else
                    write_failure_row "$target" "$op" "$clients" >>"$REPORT"
                fi
                echo "bench: row completed with errors; continuing so the report keeps comparison data" >&2
            fi
        done
    done
done

append_notes "$skipped"

echo "benchmark report: $REPORT"
