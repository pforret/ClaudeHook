#!/usr/bin/env bash
# bash_unit tests for `ClaudeHook sound <kind>`
# https://github.com/pgrange/bash_unit

root_folder=$(cd .. && pwd)
# shellcheck disable=SC2035
root_script=$(find "$root_folder" -maxdepth 1 -name "*.sh" | head -1)

test_sound_success_dry_run() {
  local actual
  actual="$("$root_script" -D sound success)"
  assert_equals "success" "$actual"
}

test_sound_warning_dry_run() {
  local actual
  actual="$("$root_script" -D sound warning)"
  assert_equals "warning" "$actual"
}

test_sound_error_dry_run() {
  local actual
  actual="$("$root_script" -D sound error)"
  assert_equals "error" "$actual"
}

test_sound_aliases_normalize_to_canonical_kind() {
  assert_equals "success" "$("$root_script" -D sound ok)"
  assert_equals "warning" "$("$root_script" -D sound warn)"
  assert_equals "error"   "$("$root_script" -D sound fail)"
}

test_sound_missing_kind_emits_error() {
  local err
  err="$("$root_script" sound 2>&1 >/dev/null)"
  assert "echo '$err' | grep -q 'missing kind'"
}

test_sound_unknown_kind_emits_error() {
  local err
  err="$("$root_script" -D sound bogus 2>&1 >/dev/null)"
  assert "echo '$err' | grep -q 'unknown kind'"
}

test_sound_fallback_emits_bell_chars() {
  # With no audio backend available the function falls back to ASCII BEL (\a) on stderr.
  # We can't assume audio tooling is missing on every CI box, so this test only runs
  # when none of afplay/paplay/aplay are installed.
  if command -v afplay >/dev/null 2>&1 \
    || command -v paplay >/dev/null 2>&1 \
    || command -v aplay  >/dev/null 2>&1; then
    return 0
  fi
  local bytes
  bytes="$("$root_script" sound error 2>&1 | od -An -c | tr -d ' \n')"
  assert_equals "\a\a\a" "$bytes"
}
