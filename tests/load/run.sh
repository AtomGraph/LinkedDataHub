#!/usr/bin/env bash

# Runs every test under tests/load against the stack on https://localhost:4443/, which must have been
# brought up with tests/load/docker-compose.load-tests.yml (see its header). No certificates: the
# suite drives the platform the way unauthenticated traffic does. Writes a CTRF report per suite to
# $TEST_RESULTS_DIR (default: out/), the same shape tests/http/run.sh writes, so
# scripts/generate_test_summary.py reads both.

hash curl 2>/dev/null || { echo >&2 "curl not on \$PATH. Aborting."; exit 1; }

export END_USER_BASE_URL="https://localhost:4443/"
export HTTP_MAX_THREADS="${HTTP_MAX_THREADS:-16}"      # keep in step with docker-compose.load-tests.yml
export TEST_RESULTS_DIR="${TEST_RESULTS_DIR:-$PWD/out}"

_ms_probe=$(date +%s%3N 2>/dev/null)
if [[ "$_ms_probe" == *N ]] || [ -z "$_ms_probe" ]; then
    function now_ms() { python3 -c 'import time; print(int(time.time()*1000))'; }
else
    function now_ms() { date +%s%3N; }
fi

function json_escape()
{
    local s="$1"
    s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\n'/\\n}"; s="${s//$'\r'/\\r}"; s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

error_count=0

function run_tests()
{
    local suite_name="$1"
    shift
    local suite_start_ms suite_end_ms
    suite_start_ms=$(now_ms)
    mkdir -p "$TEST_RESULTS_DIR"
    local results_file="$TEST_RESULTS_DIR/${suite_name}.ctrf.json"
    : > "$results_file.tests"
    local tests_total=0 tests_passed=0 tests_failed=0
    for script_pathname in "$@"
    do
        echo -n "$script_pathname"
        local log_file t_start_ms t_end_ms duration_ms exit_code status message=""
        log_file=$(mktemp)
        t_start_ms=$(now_ms)
        ( cd "$(dirname "$script_pathname")" || exit; bash -e "$(basename "$script_pathname")"; ) > "$log_file" 2>&1
        exit_code=$?
        t_end_ms=$(now_ms)
        duration_ms=$(( t_end_ms - t_start_ms ))
        if [[ $exit_code == "0" ]]; then
            echo "   ok"; status="passed"; (( tests_passed += 1 ))
        else
            echo "   failed"; status="failed"; (( tests_failed += 1 )); (( error_count += 1 ))
            cat "$log_file"
            message=$(tail -c 4096 "$log_file")
        fi
        (( tests_total += 1 ))
        {
            printf '    {"name":"%s","status":"%s","duration":%s,"suite":"%s"' "$(json_escape "${script_pathname#./}")" "$status" "$duration_ms" "$(json_escape "$suite_name")"
            [ -n "$message" ] && printf ',"message":"%s"' "$(json_escape "$message")"
            printf '}\n'
        } >> "$results_file.tests"
        rm -f "$log_file"
    done
    suite_end_ms=$(now_ms)
    {
        printf '{\n  "results": {\n    "tool": {"name": "load-tests-run.sh"},\n    "summary": {\n'
        printf '      "tests": %s,\n      "passed": %s,\n      "failed": %s,\n' "$tests_total" "$tests_passed" "$tests_failed"
        printf '      "pending": 0,\n      "skipped": 0,\n      "other": 0,\n      "suites": 1,\n'
        printf '      "start": %s,\n      "stop": %s\n    },\n    "tests": [\n' "$suite_start_ms" "$suite_end_ms"
        awk 'NR>1 {printf ",\n"} {printf "%s", $0}' "$results_file.tests"
        printf '\n    ]\n  }\n}\n'
    } > "$results_file"
    rm -f "$results_file.tests"
    return $tests_failed
}

# the platform must be answering before the burst, or the assertion measures the boot instead
until [ "$(curl -k -s -o /dev/null -w '%{http_code}' --max-time 5 "$END_USER_BASE_URL")" = 403 ]; do sleep 1; done

run_tests "load" $(find . -maxdepth 1 -type f -name '*.sh' ! -name 'run.sh' | sort)

echo "### Failed tests: $error_count"
if [ "$error_count" -gt 0 ]; then
    echo "A failed burst leaves the platform wedged: restart it before running anything else against this stack." >&2
    exit 1
fi
