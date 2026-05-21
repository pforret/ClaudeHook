#!/usr/bin/env bash
# bash_unit tests for `ClaudeHook title <status>`
# https://github.com/pgrange/bash_unit

root_folder=$(cd .. && pwd)
# shellcheck disable=SC2035
root_script=$(find "$root_folder" -maxdepth 1 -name "*.sh" | head -1)

test_title_dry_run_success() {
  local tmpdir base actual
  tmpdir="$(mktemp -d)"
  base="$(basename "$tmpdir")"
  actual="$(cd "$tmpdir" && "$root_script" -D title success)"
  assert_equals "✅ $base" "$actual"
  rm -rf "$tmpdir"
}

test_title_dry_run_warning() {
  local tmpdir base actual
  tmpdir="$(mktemp -d)"
  base="$(basename "$tmpdir")"
  actual="$(cd "$tmpdir" && "$root_script" -D title warning)"
  assert_equals "⚠️ $base" "$actual"
  rm -rf "$tmpdir"
}

test_title_dry_run_error() {
  local tmpdir base actual
  tmpdir="$(mktemp -d)"
  base="$(basename "$tmpdir")"
  actual="$(cd "$tmpdir" && "$root_script" -D title error)"
  assert_equals "⛔ $base" "$actual"
  rm -rf "$tmpdir"
}

test_title_dry_run_attention() {
  local tmpdir base actual
  tmpdir="$(mktemp -d)"
  base="$(basename "$tmpdir")"
  actual="$(cd "$tmpdir" && "$root_script" -D title attention)"
  assert_equals "🔔 $base" "$actual"
  rm -rf "$tmpdir"
}

test_title_clear_drops_emoji() {
  local tmpdir base actual
  tmpdir="$(mktemp -d)"
  base="$(basename "$tmpdir")"
  actual="$(cd "$tmpdir" && "$root_script" -D title clear)"
  assert_equals "$base" "$actual"
  rm -rf "$tmpdir"
}

test_title_uses_app_name_from_env() {
  local tmpdir actual
  tmpdir="$(mktemp -d)"
  echo 'APP_NAME=Hermes' > "$tmpdir/.env"
  actual="$(cd "$tmpdir" && "$root_script" -D title success)"
  assert_equals "✅ Hermes" "$actual"
  rm -rf "$tmpdir"
}

test_title_aliases_normalize_to_canonical_status() {
  local tmpdir base
  tmpdir="$(mktemp -d)"
  base="$(basename "$tmpdir")"
  assert_equals "✅ $base" "$(cd "$tmpdir" && "$root_script" -D title ok)"
  assert_equals "⚠️ $base" "$(cd "$tmpdir" && "$root_script" -D title warn)"
  assert_equals "⛔ $base" "$(cd "$tmpdir" && "$root_script" -D title fail)"
  rm -rf "$tmpdir"
}

test_title_missing_status_emits_error() {
  local err
  err="$("$root_script" title 2>&1 >/dev/null)"
  assert "echo '$err' | grep -q 'missing status'"
}

test_title_unknown_status_emits_error() {
  local err
  err="$("$root_script" -D title bogus 2>&1 >/dev/null)"
  assert "echo '$err' | grep -q 'unknown status'"
}
