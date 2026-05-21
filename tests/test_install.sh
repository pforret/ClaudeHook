#!/usr/bin/env bash
# bash_unit tests for `ClaudeHook install`
# https://github.com/pgrange/bash_unit

root_folder=$(cd .. && pwd)
# shellcheck disable=SC2035
root_script=$(find "$root_folder" -maxdepth 1 -name "*.sh" | head -1)

test_install_force_global_creates_all_hooks() {
  local fake_home
  fake_home="$(mktemp -d)"
  HOME="$fake_home" "$root_script" -f install global >/dev/null
  local settings="$fake_home/.claude/settings.json"
  assert "test -f $settings"
  assert_equals 5 "$(jq '.hooks | keys | length' "$settings")"
  rm -rf "$fake_home"
}

test_install_is_idempotent() {
  local fake_home
  fake_home="$(mktemp -d)"
  HOME="$fake_home" "$root_script" -f install global >/dev/null
  HOME="$fake_home" "$root_script" -f install global >/dev/null
  local settings="$fake_home/.claude/settings.json"
  assert_equals 1 "$(jq '.hooks.Stop | length' "$settings")"
  assert_equals 1 "$(jq '.hooks.Notification | length' "$settings")"
  assert_equals 1 "$(jq '.hooks.PreCompact | length' "$settings")"
  rm -rf "$fake_home"
}

test_install_produces_valid_json() {
  local fake_home
  fake_home="$(mktemp -d)"
  HOME="$fake_home" "$root_script" -f install global >/dev/null
  assert "jq -e . $fake_home/.claude/settings.json >/dev/null"
  rm -rf "$fake_home"
}

test_install_hook_command_uses_absolute_path() {
  local fake_home
  fake_home="$(mktemp -d)"
  HOME="$fake_home" "$root_script" -f install global >/dev/null
  local cmd matcher
  cmd="$(jq -r '.hooks.Stop[0].hooks[0].command' "$fake_home/.claude/settings.json")"
  matcher="$(jq -r '.hooks.Stop[0].matcher' "$fake_home/.claude/settings.json")"
  # Expect: rule with matcher:"" and nested hooks[0].command = /abs/path/ClaudeHook.sh say "is done"
  assert_equals "" "$matcher"
  assert_equals "/" "${cmd:0:1}"
  case "$cmd" in
    *'say "is done"') ;;
    *) fail "Stop command does not end with: say \"is done\" - got: $cmd" ;;
  esac
  rm -rf "$fake_home"
}

test_install_repairs_legacy_flat_shape() {
  # Simulate a settings.json written by the v0.0.1 flat-shape bug.
  local fake_home
  fake_home="$(mktemp -d)"
  mkdir -p "$fake_home/.claude"
  cat >"$fake_home/.claude/settings.json" <<JSON
{"hooks":{"Stop":[{"type":"command","command":"BOGUS_OLD_CMD","timeout":10}]}}
JSON
  HOME="$fake_home" "$root_script" -f install global >/dev/null
  local settings="$fake_home/.claude/settings.json"
  # After repair: exactly 1 Stop rule, in correct nested shape, with the NEW command.
  assert_equals 1 "$(jq '.hooks.Stop | length' "$settings")"
  assert_equals "" "$(jq -r '.hooks.Stop[0].matcher' "$settings")"
  local cmd
  cmd="$(jq -r '.hooks.Stop[0].hooks[0].command' "$settings")"
  case "$cmd" in
    *'say "is done"') ;;
    *) fail "repaired Stop command should end with: say \"is done\" - got: $cmd" ;;
  esac
  # The BOGUS legacy entry must be gone, not preserved.
  assert_equals "false" "$(jq '[.hooks.Stop[].command? // empty] | length > 0' "$settings")"
  rm -rf "$fake_home"
}

test_install_project_scope_writes_to_local_dir() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  ( cd "$tmpdir" && "$root_script" -f install project >/dev/null )
  assert "test -f $tmpdir/.claude/settings.json"
  assert_equals 5 "$(jq '.hooks | keys | length' "$tmpdir/.claude/settings.json")"
  rm -rf "$tmpdir"
}
