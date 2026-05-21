#!/usr/bin/env bash
# bash_unit tests for `ClaudeHook notify [message]`
# https://github.com/pgrange/bash_unit

root_folder=$(cd .. && pwd)
# shellcheck disable=SC2035
root_script=$(find "$root_folder" -maxdepth 1 -name "*.sh" | head -1)

test_notify_dry_run_with_message() {
  local tmpdir base actual
  tmpdir="$(mktemp -d)"
  base="$(basename "$tmpdir")"
  actual="$(cd "$tmpdir" && "$root_script" -D notify "is done")"
  assert_equals "$base: is done" "$actual"
  rm -rf "$tmpdir"
}

test_notify_dry_run_uses_app_name_from_env() {
  local tmpdir actual
  tmpdir="$(mktemp -d)"
  echo 'APP_NAME=Hermes' > "$tmpdir/.env"
  actual="$(cd "$tmpdir" && "$root_script" -D notify "needs attention")"
  assert_equals "Hermes: needs attention" "$actual"
  rm -rf "$tmpdir"
}

test_notify_dry_run_empty_message_prints_just_app_name() {
  local tmpdir base actual
  tmpdir="$(mktemp -d)"
  base="$(basename "$tmpdir")"
  actual="$(cd "$tmpdir" && "$root_script" -D notify)"
  assert_equals "$base" "$actual"
  rm -rf "$tmpdir"
}
