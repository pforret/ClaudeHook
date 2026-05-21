#!/usr/bin/env bash
# bash_unit tests for `ClaudeHook say <message>`
# https://github.com/pgrange/bash_unit

root_folder=$(cd .. && pwd)
# shellcheck disable=SC2035
root_script=$(find "$root_folder" -maxdepth 1 -name "*.sh" | head -1)

test_say_uses_basename_when_no_env() {
  local tmpdir base expected actual
  tmpdir="$(mktemp -d)"
  base="$(basename "$tmpdir")"
  expected="$base hello"
  actual="$(cd "$tmpdir" && "$root_script" -D say hello)"
  assert_equals "$expected" "$actual"
  rm -rf "$tmpdir"
}

test_say_uses_app_name_from_env() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  echo 'APP_NAME=Hermes' > "$tmpdir/.env"
  local actual
  actual="$(cd "$tmpdir" && "$root_script" -D say hello)"
  assert_equals "Hermes hello" "$actual"
  rm -rf "$tmpdir"
}

test_say_empty_message_prints_just_app_name() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  echo 'APP_NAME=Foo' > "$tmpdir/.env"
  local actual
  actual="$(cd "$tmpdir" && "$root_script" -D say)"
  assert_equals "Foo" "$actual"
  rm -rf "$tmpdir"
}
