#!/usr/bin/env bash
# bash_unit tests for `ClaudeHook push [message]`
# https://github.com/pgrange/bash_unit

root_folder=$(cd .. && pwd)
# shellcheck disable=SC2035
root_script=$(find "$root_folder" -maxdepth 1 -name "*.sh" | head -1)

# Scrub all push-related env vars so tests are deterministic regardless of the
# developer's shell. Each test reads creds exclusively from a per-tmpdir .env.
push_run() {
  env -u PUSH_CHANNEL \
      -u NTFY_TOPIC \
      -u PUSHOVER_USER_KEY -u PUSHOVER_APP_TOKEN \
      -u TELEGRAM_BOT_TOKEN -u TELEGRAM_CHAT_ID \
      -u SLACK_WEBHOOK_URL -u DISCORD_WEBHOOK_URL \
      "$root_script" "$@"
}

test_push_with_no_channel_is_silent() {
  local tmpdir out err
  tmpdir="$(mktemp -d)"
  out="$(cd "$tmpdir" && push_run -D push "hello" 2>/tmp/push_err_$$)"
  err="$(cat /tmp/push_err_$$)"
  assert_equals "" "$out"
  assert_equals "" "$err"
  rm -f /tmp/push_err_$$
  rm -rf "$tmpdir"
}

test_push_channel_set_but_creds_missing_warns() {
  local tmpdir err
  tmpdir="$(mktemp -d)"
  echo 'PUSH_CHANNEL=ntfy' > "$tmpdir/.env"
  err="$(cd "$tmpdir" && push_run -D push "hello" 2>&1 >/dev/null)"
  assert "echo '$err' | grep -q 'NTFY_TOPIC'"
  assert "echo '$err' | grep -q 'PUSH_CHANNEL=ntfy is set'"
  rm -rf "$tmpdir"
}

test_push_unknown_channel_warns() {
  local tmpdir err
  tmpdir="$(mktemp -d)"
  echo 'PUSH_CHANNEL=bogus' > "$tmpdir/.env"
  err="$(cd "$tmpdir" && push_run -D push "hello" 2>&1 >/dev/null)"
  assert "echo '$err' | grep -q 'unknown PUSH_CHANNEL'"
  rm -rf "$tmpdir"
}

test_push_ntfy_dry_run_expands_bare_topic() {
  local tmpdir base out
  tmpdir="$(mktemp -d)"
  base="$(basename "$tmpdir")"
  cat > "$tmpdir/.env" <<EOF
PUSH_CHANNEL=ntfy
NTFY_TOPIC=my-secret
EOF
  out="$(cd "$tmpdir" && push_run -D push "is done")"
  case "$out" in
    *'https://ntfy.sh/my-secret'*"Title: $base"*'is done'*) ;;
    *) fail "ntfy dry-run should expand bare topic + include title/body - got: $out" ;;
  esac
  rm -rf "$tmpdir"
}

test_push_ntfy_dry_run_keeps_full_url() {
  local tmpdir out
  tmpdir="$(mktemp -d)"
  cat > "$tmpdir/.env" <<EOF
PUSH_CHANNEL=ntfy
NTFY_TOPIC=https://ntfy.example.com/topic
EOF
  out="$(cd "$tmpdir" && push_run -D push "hi")"
  case "$out" in
    *'https://ntfy.example.com/topic'*) ;;
    *) fail "ntfy dry-run should keep full URL - got: $out" ;;
  esac
  case "$out" in
    *'https://ntfy.sh/'*) fail "ntfy dry-run should NOT prepend ntfy.sh when full URL given - got: $out" ;;
    *) ;;
  esac
  rm -rf "$tmpdir"
}

test_push_pushover_dry_run() {
  local tmpdir base out
  tmpdir="$(mktemp -d)"
  base="$(basename "$tmpdir")"
  cat > "$tmpdir/.env" <<EOF
PUSH_CHANNEL=pushover
PUSHOVER_USER_KEY=u1
PUSHOVER_APP_TOKEN=t1
EOF
  out="$(cd "$tmpdir" && push_run -D push "is done")"
  case "$out" in
    *'pushover'*"title=$base"*'message=is done'*) ;;
    *) fail "pushover dry-run output unexpected - got: $out" ;;
  esac
  rm -rf "$tmpdir"
}

test_push_pushover_missing_one_cred_warns() {
  local tmpdir err
  tmpdir="$(mktemp -d)"
  cat > "$tmpdir/.env" <<EOF
PUSH_CHANNEL=pushover
PUSHOVER_USER_KEY=u1
EOF
  err="$(cd "$tmpdir" && push_run -D push "hi" 2>&1 >/dev/null)"
  assert "echo '$err' | grep -q 'PUSHOVER_APP_TOKEN'"
  # Should NOT mention the var that IS set
  assert "! echo '$err' | grep -q 'PUSHOVER_USER_KEY'"
  rm -rf "$tmpdir"
}

test_push_telegram_dry_run() {
  local tmpdir base out
  tmpdir="$(mktemp -d)"
  base="$(basename "$tmpdir")"
  cat > "$tmpdir/.env" <<EOF
PUSH_CHANNEL=telegram
TELEGRAM_BOT_TOKEN=botabc
TELEGRAM_CHAT_ID=12345
EOF
  out="$(cd "$tmpdir" && push_run -D push "is done")"
  case "$out" in
    *'telegram'*'chat=12345'*"$base: is done"*) ;;
    *) fail "telegram dry-run output unexpected - got: $out" ;;
  esac
  rm -rf "$tmpdir"
}

test_push_slack_dry_run() {
  local tmpdir base out
  tmpdir="$(mktemp -d)"
  base="$(basename "$tmpdir")"
  cat > "$tmpdir/.env" <<EOF
PUSH_CHANNEL=slack
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/T/B/X
EOF
  out="$(cd "$tmpdir" && push_run -D push "is done")"
  case "$out" in
    *'slack'*"text=$base: is done"*) ;;
    *) fail "slack dry-run output unexpected - got: $out" ;;
  esac
  rm -rf "$tmpdir"
}

test_push_discord_dry_run() {
  local tmpdir base out
  tmpdir="$(mktemp -d)"
  base="$(basename "$tmpdir")"
  cat > "$tmpdir/.env" <<EOF
PUSH_CHANNEL=discord
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/123/abc
EOF
  out="$(cd "$tmpdir" && push_run -D push "is done")"
  case "$out" in
    *'discord'*"content=$base: is done"*) ;;
    *) fail "discord dry-run output unexpected - got: $out" ;;
  esac
  rm -rf "$tmpdir"
}

test_push_whatsapp_dry_run_substitutes_placeholders() {
  local tmpdir base out
  tmpdir="$(mktemp -d)"
  base="$(basename "$tmpdir")"
  cat > "$tmpdir/.env" <<EOF
PUSH_CHANNEL=whatsapp
WHATSAPP_TO=+31612345678
WHATSAPP_CMD=whatsapp-cli send -t {to} -m {msg}
EOF
  out="$(cd "$tmpdir" && push_run -D push "is done")"
  # Dry-run prints %q-quoted argv, so spaces inside {msg} render as '\ '.
  # Check each placeholder substitution individually.
  case "$out" in *'whatsapp EXEC'*) ;; *) fail "missing EXEC prefix - got: $out" ;; esac
  case "$out" in *'whatsapp-cli send -t +31612345678 -m'*) ;; *) fail "missing prefix args / {to} substitution - got: $out" ;; esac
  case "$out" in *"$base"*) ;; *) fail "missing app name in {msg} - got: $out" ;; esac
  case "$out" in *'is'*'done'*) ;; *) fail "missing message tokens - got: $out" ;; esac
  rm -rf "$tmpdir"
}

test_push_whatsapp_missing_creds_warns() {
  local tmpdir err
  tmpdir="$(mktemp -d)"
  echo 'PUSH_CHANNEL=whatsapp' > "$tmpdir/.env"
  err="$(cd "$tmpdir" && push_run -D push "hi" 2>&1 >/dev/null)"
  # Both required vars should be named, joined with a space (not a newline).
  case "$err" in
    *'WHATSAPP_TO WHATSAPP_CMD'*) ;;
    *) fail "whatsapp missing-creds alert should list both vars on one line - got: $err" ;;
  esac
  rm -rf "$tmpdir"
}

test_push_whatsapp_preserves_multiword_message_as_one_arg() {
  # Use a recording wrapper as the WHATSAPP_CMD binary and verify it receives
  # the message as a single argv element, not re-split on spaces.
  local tmpdir base
  tmpdir="$(mktemp -d)"
  base="$(basename "$tmpdir")"
  local argv_log="$tmpdir/argv.log"
  local wrapper="$tmpdir/wa-wrapper.sh"
  cat > "$wrapper" <<WRAP
#!/bin/bash
{
  printf "argc=%d\n" "\$#"
  i=0
  for a in "\$@"; do
    printf "argv[%d]=%s\n" "\$i" "\$a"
    i=\$((i+1))
  done
} >> "$argv_log"
WRAP
  chmod +x "$wrapper"
  cat > "$tmpdir/.env" <<EOF
PUSH_CHANNEL=whatsapp
WHATSAPP_TO=+31612345678
WHATSAPP_CMD=$wrapper send -t {to} -m {msg}
EOF
  ( cd "$tmpdir" && push_run push "is done now" >/dev/null 2>&1 )
  assert "test -f $argv_log"
  # Expect: argc=5; the last argv contains the full multi-word message.
  assert "grep -q '^argc=5$' $argv_log"
  assert "grep -q '^argv\\[4\\]=$base: is done now$' $argv_log"
  rm -rf "$tmpdir"
}

test_push_whatsapp_missing_cli_warns() {
  local tmpdir err
  tmpdir="$(mktemp -d)"
  cat > "$tmpdir/.env" <<EOF
PUSH_CHANNEL=whatsapp
WHATSAPP_TO=+31612345678
WHATSAPP_CMD=definitely-not-a-real-binary-xyz {to} {msg}
EOF
  err="$(cd "$tmpdir" && push_run push "hi" 2>&1 >/dev/null)"
  case "$err" in
    *"definitely-not-a-real-binary-xyz"*"not found"*) ;;
    *) fail "whatsapp missing-binary alert should mention the binary - got: $err" ;;
  esac
  rm -rf "$tmpdir"
}

test_push_uses_app_name_from_env() {
  local tmpdir out
  tmpdir="$(mktemp -d)"
  cat > "$tmpdir/.env" <<EOF
APP_NAME=Hermes
PUSH_CHANNEL=ntfy
NTFY_TOPIC=t
EOF
  out="$(cd "$tmpdir" && push_run -D push "is done")"
  case "$out" in
    *'Title: Hermes'*) ;;
    *) fail "push should use APP_NAME for title - got: $out" ;;
  esac
  rm -rf "$tmpdir"
}
