//go:build ignore

package main

import (
	"bufio"
	"errors"
	"flag"
	"fmt"
	"io"
	"net"
	"os"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"
)

type config struct {
	target   string
	host     string
	port     int
	op       string
	clients  int
	requests int
	keys     int
	valueLen int
	timeout  time.Duration
	format   string
	prepare  bool
}

type workerResult struct {
	latencies []int64
	errors    int
	firstErr  string
}

type clientConn struct {
	target string
	conn   net.Conn
	r      *bufio.Reader
	w      *bufio.Writer
}

type summary struct {
	target      string
	op          string
	clients     int
	requests    int
	keys        int
	valueLen    int
	duration    time.Duration
	errors      int
	avgMicros   int64
	p50Micros   int64
	p95Micros   int64
	p99Micros   int64
	requestsSec float64
	firstErr    string
}

func main() {
	cfg := parseFlags()
	keys := makeKeys(cfg.keys)
	value := makeValue(cfg.valueLen)

	if cfg.prepare && cfg.op != "ping" {
		if err := prepareData(cfg, keys, value); err != nil {
			fmt.Fprintf(os.Stderr, "prepare failed: %v\n", err)
			os.Exit(1)
		}
	}

	sum, err := runBenchmark(cfg, keys, value)
	if err != nil {
		fmt.Fprintf(os.Stderr, "benchmark failed: %v\n", err)
		os.Exit(1)
	}
	printSummary(cfg.format, sum)
	if sum.errors != 0 {
		fmt.Fprintf(os.Stderr, "errors=%d first_error=%s\n", sum.errors, sum.firstErr)
		os.Exit(2)
	}
}

func parseFlags() config {
	var cfg config
	flag.StringVar(&cfg.target, "target", "surgekv", "target protocol: surgekv, redis, or valkey")
	flag.StringVar(&cfg.host, "host", "127.0.0.1", "target host")
	flag.IntVar(&cfg.port, "port", 7379, "target TCP port")
	flag.StringVar(&cfg.op, "op", "mixed", "operation: ping, get, set, or mixed")
	flag.IntVar(&cfg.clients, "clients", 16, "concurrent client connections")
	flag.IntVar(&cfg.requests, "requests", 200, "total requests")
	flag.IntVar(&cfg.keys, "keys", 50, "key cardinality")
	flag.IntVar(&cfg.valueLen, "value-bytes", 64, "approximate value size")
	flag.DurationVar(&cfg.timeout, "timeout", 3*time.Second, "per-request timeout")
	flag.StringVar(&cfg.format, "format", "text", "output format: text or markdown")
	flag.BoolVar(&cfg.prepare, "prepare", true, "preload keys before timed run")
	flag.Parse()

	if cfg.target != "surgekv" && cfg.target != "redis" && cfg.target != "valkey" {
		fatalf("unsupported target %q", cfg.target)
	}
	if cfg.op != "ping" && cfg.op != "get" && cfg.op != "set" && cfg.op != "mixed" {
		fatalf("unsupported op %q", cfg.op)
	}
	if cfg.clients <= 0 {
		fatalf("clients must be greater than zero")
	}
	if cfg.requests <= 0 {
		fatalf("requests must be greater than zero")
	}
	if cfg.keys <= 0 {
		fatalf("keys must be greater than zero")
	}
	if cfg.valueLen <= 0 {
		fatalf("value-bytes must be greater than zero")
	}
	return cfg
}

func fatalf(format string, args ...any) {
	fmt.Fprintf(os.Stderr, format+"\n", args...)
	os.Exit(1)
}

func makeKeys(count int) []string {
	keys := make([]string, count)
	for i := range keys {
		keys[i] = fmt.Sprintf("bench:%d", i)
	}
	return keys
}

func makeValue(size int) string {
	const prefix = `{"v":"`
	const suffix = `"}`
	if size <= len(prefix)+len(suffix) {
		return `{"v":""}`
	}
	return prefix + strings.Repeat("x", size-len(prefix)-len(suffix)) + suffix
}

func prepareData(cfg config, keys []string, value string) error {
	c, err := dialTarget(cfg)
	if err != nil {
		return err
	}
	defer c.conn.Close()

	for _, key := range keys {
		// Preload is outside the timed run, but it must still be bounded so a
		// wedged server becomes a benchmark error instead of a stuck script.
		c.conn.SetDeadline(time.Now().Add(cfg.timeout))
		if cfg.target == "surgekv" {
			if err := c.surgeCommand("NEW " + key + " " + value); err != nil {
				if !strings.Contains(err.Error(), "ERROR EXISTS") {
					return err
				}
				c.conn.SetDeadline(time.Now().Add(cfg.timeout))
				if err := c.surgeCommand("SET " + key + " " + value); err != nil {
					return err
				}
			}
		} else {
			if err := c.redisCommand("SET", key, value); err != nil {
				return err
			}
		}
	}
	return nil
}

func runBenchmark(cfg config, keys []string, value string) (summary, error) {
	start := make(chan struct{})
	results := make(chan workerResult, cfg.clients)
	var wg sync.WaitGroup

	base := cfg.requests / cfg.clients
	rem := cfg.requests % cfg.clients
	seqStart := 0

	startedAt := time.Now()
	for i := 0; i < cfg.clients; i++ {
		count := base
		if i < rem {
			count++
		}
		firstSeq := seqStart
		seqStart += count
		wg.Add(1)
		go func(workerID int, requests int, first int) {
			defer wg.Done()
			<-start
			results <- runWorker(cfg, keys, value, requests, first)
		}(i, count, firstSeq)
	}

	startedAt = time.Now()
	close(start)
	wg.Wait()
	duration := time.Since(startedAt)
	close(results)

	var latencies []int64
	errCount := 0
	firstErr := ""
	for result := range results {
		latencies = append(latencies, result.latencies...)
		errCount += result.errors
		if firstErr == "" && result.firstErr != "" {
			firstErr = result.firstErr
		}
	}
	sort.Slice(latencies, func(i, j int) bool { return latencies[i] < latencies[j] })

	sum := summary{
		target:      cfg.target,
		op:          cfg.op,
		clients:     cfg.clients,
		requests:    cfg.requests,
		keys:        cfg.keys,
		valueLen:    cfg.valueLen,
		duration:    duration,
		errors:      errCount,
		avgMicros:   average(latencies),
		p50Micros:   percentile(latencies, 0.50),
		p95Micros:   percentile(latencies, 0.95),
		p99Micros:   percentile(latencies, 0.99),
		requestsSec: float64(cfg.requests) / duration.Seconds(),
		firstErr:    firstErr,
	}
	return sum, nil
}

func runWorker(cfg config, keys []string, value string, requests int, firstSeq int) workerResult {
	result := workerResult{latencies: make([]int64, 0, requests)}
	c, err := dialTarget(cfg)
	if err != nil {
		result.errors = requests
		result.firstErr = err.Error()
		return result
	}
	defer c.conn.Close()

	for i := 0; i < requests; i++ {
		seq := firstSeq + i
		key := keys[seq%len(keys)]
		op := cfg.op
		if op == "mixed" {
			if seq%2 == 0 {
				op = "set"
			} else {
				op = "get"
			}
		}

		startedAt := time.Now()
		c.conn.SetDeadline(startedAt.Add(cfg.timeout))
		if err := c.do(op, key, value); err != nil {
			result.errors++
			if result.firstErr == "" {
				result.firstErr = err.Error()
			}
			continue
		}
		result.latencies = append(result.latencies, time.Since(startedAt).Microseconds())
	}
	return result
}

func dialTarget(cfg config) (*clientConn, error) {
	addr := net.JoinHostPort(cfg.host, strconv.Itoa(cfg.port))
	conn, err := net.DialTimeout("tcp", addr, cfg.timeout)
	if err != nil {
		return nil, err
	}
	return &clientConn{
		target: cfg.target,
		conn:   conn,
		r:      bufio.NewReaderSize(conn, 4096),
		w:      bufio.NewWriterSize(conn, 4096),
	}, nil
}

func (c *clientConn) do(op string, key string, value string) error {
	if c.target == "surgekv" {
		switch op {
		case "ping":
			return c.surgeCommand("PING")
		case "get":
			return c.surgeCommand("GET " + key)
		case "set":
			return c.surgeCommand("SET " + key + " " + value)
		default:
			return fmt.Errorf("unsupported op %q", op)
		}
	}

	switch op {
	case "ping":
		return c.redisCommand("PING")
	case "get":
		return c.redisCommand("GET", key)
	case "set":
		return c.redisCommand("SET", key, value)
	default:
		return fmt.Errorf("unsupported op %q", op)
	}
}

func (c *clientConn) surgeCommand(line string) error {
	if _, err := c.w.WriteString(line + "\n"); err != nil {
		return err
	}
	if err := c.w.Flush(); err != nil {
		return err
	}
	resp, err := c.r.ReadString('\n')
	if err != nil {
		return err
	}
	resp = strings.TrimRight(resp, "\r\n")
	if strings.HasPrefix(resp, "ERROR ") {
		return errors.New(resp)
	}
	if line == "PING" && resp != "PONG" {
		return fmt.Errorf("expected PONG, got %q", resp)
	}
	if strings.HasPrefix(line, "GET ") && !strings.HasPrefix(resp, "VALUE ") {
		return fmt.Errorf("expected VALUE, got %q", resp)
	}
	if strings.HasPrefix(line, "SET ") && !strings.HasPrefix(resp, "OK") {
		return fmt.Errorf("expected OK, got %q", resp)
	}
	if strings.HasPrefix(line, "NEW ") && !strings.HasPrefix(resp, "OK") {
		return errors.New(resp)
	}
	return nil
}

func (c *clientConn) redisCommand(parts ...string) error {
	if err := writeRESP(c.w, parts); err != nil {
		return err
	}
	if err := c.w.Flush(); err != nil {
		return err
	}
	_, err := readRESP(c.r)
	return err
}

func writeRESP(w *bufio.Writer, parts []string) error {
	if _, err := fmt.Fprintf(w, "*%d\r\n", len(parts)); err != nil {
		return err
	}
	for _, part := range parts {
		if _, err := fmt.Fprintf(w, "$%d\r\n%s\r\n", len(part), part); err != nil {
			return err
		}
	}
	return nil
}

func readRESP(r *bufio.Reader) (string, error) {
	prefix, err := r.ReadByte()
	if err != nil {
		return "", err
	}
	switch prefix {
	case '+', ':':
		line, err := r.ReadString('\n')
		return strings.TrimRight(line, "\r\n"), err
	case '-':
		line, _ := r.ReadString('\n')
		return "", errors.New(strings.TrimRight(line, "\r\n"))
	case '$':
		line, err := r.ReadString('\n')
		if err != nil {
			return "", err
		}
		n, err := strconv.Atoi(strings.TrimSpace(line))
		if err != nil {
			return "", err
		}
		if n < 0 {
			return "", nil
		}
		buf := make([]byte, n+2)
		if _, err := io.ReadFull(r, buf); err != nil {
			return "", err
		}
		return string(buf[:n]), nil
	default:
		return "", fmt.Errorf("unexpected RESP prefix %q", prefix)
	}
}

func average(values []int64) int64 {
	if len(values) == 0 {
		return 0
	}
	var total int64
	for _, v := range values {
		total += v
	}
	return total / int64(len(values))
}

func percentile(values []int64, p float64) int64 {
	if len(values) == 0 {
		return 0
	}
	idx := int(float64(len(values)-1) * p)
	return values[idx]
}

func printSummary(format string, sum summary) {
	switch format {
	case "markdown":
		fmt.Printf("| %s | %s | %d | %d | %d | %d | %.0f | %d | %d | %d | %d | %d |\n",
			sum.target, sum.op, sum.clients, sum.requests, sum.keys, sum.valueLen,
			sum.requestsSec, sum.avgMicros, sum.p50Micros, sum.p95Micros, sum.p99Micros, sum.errors)
	default:
		fmt.Printf("target=%s op=%s clients=%d requests=%d keys=%d value_bytes=%d total_ms=%d rps=%.0f avg_us=%d p50_us=%d p95_us=%d p99_us=%d errors=%d\n",
			sum.target, sum.op, sum.clients, sum.requests, sum.keys, sum.valueLen,
			sum.duration.Milliseconds(), sum.requestsSec, sum.avgMicros, sum.p50Micros,
			sum.p95Micros, sum.p99Micros, sum.errors)
	}
}
