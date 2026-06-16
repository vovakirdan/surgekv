#!/usr/bin/env bash
set -euo pipefail

HOST="${SURGEKV_HOST:-127.0.0.1}"
PORT="${1:-${SURGEKV_PORT:-$((20000 + RANDOM % 20000))}}"
BIN="${SURGEKV_BIN:-./target/debug/surgekv}"
READ_TIMEOUT="${SURGEKV_READ_TIMEOUT:-2}"
BUILD="${SURGEKV_BUILD:-1}"

tmp_dir="$(mktemp -d)"
server_log="$tmp_dir/server.log"
server_pid=""
c1_pid=""
c2_pid=""
c1_in_fd=""
c1_out_fd=""
c2_in_fd=""
c2_out_fd=""

fail() {
    echo "FAIL: $*" >&2
    if [[ -s "$server_log" ]]; then
        echo "--- server log ---" >&2
        cat "$server_log" >&2
    fi
    exit 1
}

close_fd() {
    local fd="${1:-}"
    if [[ -n "$fd" ]]; then
        eval "exec ${fd}<&-"
    fi
}

cleanup() {
    set +e
    close_fd "$c1_in_fd"
    close_fd "$c1_out_fd"
    close_fd "$c2_in_fd"
    close_fd "$c2_out_fd"
    if [[ -n "$c1_pid" ]]; then
        kill "$c1_pid" 2>/dev/null
        wait "$c1_pid" 2>/dev/null
    fi
    if [[ -n "$c2_pid" ]]; then
        kill "$c2_pid" 2>/dev/null
        wait "$c2_pid" 2>/dev/null
    fi
    if [[ -n "$server_pid" ]]; then
        kill "$server_pid" 2>/dev/null
        wait "$server_pid" 2>/dev/null
    fi
    rm -rf "$tmp_dir"
}
trap cleanup EXIT

require_tool() {
    local name="$1"
    command -v "$name" >/dev/null 2>&1 || fail "missing required tool: $name"
}

wait_for_server() {
    local response=""
    local i=0
    while [[ "$i" -lt 50 ]]; do
        if ! kill -0 "$server_pid" 2>/dev/null; then
            fail "server exited before accepting connections"
        fi

        response="$(printf 'PING\n' | nc -w 1 "$HOST" "$PORT" 2>/dev/null | head -n 1 | tr -d '\r' || true)"
        if [[ "$response" == "PONG" ]]; then
            return 0
        fi

        sleep 0.1
        i=$((i + 1))
    done

    fail "server did not answer PING on ${HOST}:${PORT}"
}

start_client() {
    local name="$1"
    local pid_var="$2"
    local in_fd_var="$3"
    local out_fd_var="$4"
    local in_fifo="$tmp_dir/${name}.in"
    local out_fifo="$tmp_dir/${name}.out"
    local in_fd=""
    local out_fd=""

    mkfifo "$in_fifo" "$out_fifo"
    exec {in_fd}<>"$in_fifo"
    exec {out_fd}<>"$out_fifo"

    nc "$HOST" "$PORT" <"$in_fifo" >"$out_fifo" &
    local pid="$!"

    printf -v "$pid_var" '%s' "$pid"
    printf -v "$in_fd_var" '%s' "$in_fd"
    printf -v "$out_fd_var" '%s' "$out_fd"
}

send_line() {
    local fd="$1"
    local line="$2"
    printf '%s\n' "$line" >&"$fd"
}

read_line() {
    local fd="$1"
    local line=""
    if ! IFS= read -r -t "$READ_TIMEOUT" -u "$fd" line; then
        fail "timed out waiting for response"
    fi
    printf '%s\n' "${line%$'\r'}"
}

expect_line() {
    local fd="$1"
    local expected="$2"
    local actual=""
    actual="$(read_line "$fd")"
    if [[ "$actual" != "$expected" ]]; then
        fail "expected '$expected', got '$actual'"
    fi
    echo "ok: $expected"
}

require_tool nc
require_tool surge

if [[ "$BUILD" != "0" ]]; then
    surge build .
fi

[[ -x "$BIN" ]] || fail "binary not found or not executable: $BIN"

"$BIN" --port "$PORT" --workers 4 --shards 4 --expiry-interval-ms 250 >"$server_log" 2>&1 &
server_pid="$!"
wait_for_server
echo "server: ${HOST}:${PORT}"

start_client c1 c1_pid c1_in_fd c1_out_fd
send_line "$c1_in_fd" "PING"
expect_line "$c1_out_fd" "PONG"
send_line "$c1_in_fd" "NEW smoke:key 1"
expect_line "$c1_out_fd" "OK version=1"
send_line "$c1_in_fd" "OWN smoke:key TTL 5"
expect_line "$c1_out_fd" "OK ttl=5"

start_client c2 c2_pid c2_in_fd c2_out_fd
send_line "$c2_in_fd" "PING"
expect_line "$c2_out_fd" "PONG"
send_line "$c2_in_fd" "SET smoke:key 2"
expect_line "$c2_out_fd" "ERROR LOCKED key is locked"

send_line "$c1_in_fd" "RELEASE smoke:key"
expect_line "$c1_out_fd" "OK"
send_line "$c2_in_fd" "SET smoke:key 2"
expect_line "$c2_out_fd" "OK version=2"
send_line "$c2_in_fd" "GET smoke:key"
expect_line "$c2_out_fd" "VALUE 2"
send_line "$c2_in_fd" "WHOAMI"
expect_line "$c2_out_fd" "CLIENT id=client-3 owned=0 borrowed=0"

send_line "$c2_in_fd" "NEW user:2 2"
expect_line "$c2_out_fd" "OK version=1"
send_line "$c2_in_fd" "NEW post:1 1"
expect_line "$c2_out_fd" "OK version=1"
send_line "$c2_in_fd" "NEW user:1 1"
expect_line "$c2_out_fd" "OK version=1"
send_line "$c2_in_fd" "KEYS *"
expect_line "$c2_out_fd" "LIST"
expect_line "$c2_out_fd" "post:1"
expect_line "$c2_out_fd" "smoke:key"
expect_line "$c2_out_fd" "user:1"
expect_line "$c2_out_fd" "user:2"
expect_line "$c2_out_fd" "END"

send_line "$c2_in_fd" "OWN smoke:key TTL 1"
expect_line "$c2_out_fd" "OK ttl=1"
sleep 2
send_line "$c1_in_fd" "SET smoke:key 3"
expect_line "$c1_out_fd" "OK version=3"

kill "$c1_pid" 2>/dev/null || true
wait "$c1_pid" 2>/dev/null || true
c1_pid=""
sleep 0.2

send_line "$c2_in_fd" "PING"
expect_line "$c2_out_fd" "PONG"

echo "concurrency smoke passed"
