![bash_unit CI](https://github.com/pforret/ClaudeHook/workflows/bash_unit%20CI/badge.svg)
![Shellcheck CI](https://github.com/pforret/ClaudeHook/workflows/Shellcheck%20CI/badge.svg)
![GH Language](https://img.shields.io/github/languages/top/pforret/ClaudeHook)
![GH stars](https://img.shields.io/github/stars/pforret/ClaudeHook)
![GH tag](https://img.shields.io/github/v/tag/pforret/ClaudeHook)
![GH License](https://img.shields.io/github/license/pforret/ClaudeHook)
[![basher install](https://img.shields.io/badge/basher-install-white?logo=gnu-bash&style=flat)](https://www.basher.it/package/)

# ClaudeHook

Do interesting stuff in Claude Code hooks

## 🔥 Usage

```
Program : ClaudeHook  by peter@forret.com
Purpose : Do interesting stuff in Claude Code hooks
Usage   : ClaudeHook [-h] [-Q] [-V] [-f] [-D] [-L <LOG_DIR>] [-T <TMP_DIR>] <action> <input?>
Flags, options and parameters:
    -h|--help        : [flag] show usage
    -Q|--QUIET       : [flag] no output
    -V|--VERBOSE     : [flag] also show debug messages
    -f|--FORCE       : [flag] do not ask for confirmation (always yes)
    -D|--DRY_RUN     : [flag] print message instead of speaking (for testing)
    -L|--LOG_DIR <?> : [option] folder for log files
    -T|--TMP_DIR <?> : [option] folder for temp files
    <action>         : [choice] action to perform  [options: say,sound,title,notify,install,check,env,update]
    <input>          : [parameter] message for `say`/`notify`, kind for `sound`, status for `title`, or scope for `install` (optional)
```

## ⚡️ Setup — one-step install

```bash
> ClaudeHook install
Install hooks for: [p]roject only / [g]lobal (p) > g
Install Notification hook? (will say "<app> needs your attention") [y/N] y
Install Stop hook? (will say "<app> is done") [y/N] y
Install StopFailure hook? (will say "<app> encountered an error") [y/N] y
Install PreCompact hook? (will say "<app> is compacting context") [y/N] n
Install PermissionRequest hook? (will say "<app> needs permission") [y/N] y
✅ 4 hook(s) installed in /Users/me/.claude/settings.json
```

`-f` skips all prompts and installs every hook globally:

```bash
> ClaudeHook -f install
```

You can also pre-select the scope non-interactively:

```bash
> ClaudeHook -f install global    # → ~/.claude/settings.json
> ClaudeHook -f install project   # → ./.claude/settings.json
```

## 🗣️ `say` — what the hooks call

`ClaudeHook say "<message>"` speaks `<app_name> <message>` out loud using
`say` (macOS) or `spd-say` / `espeak` (Linux). `<app_name>` comes from `APP_NAME`
in `.env` if present, otherwise `basename $PWD`.

```bash
> cd ~/Code/myproject
> ClaudeHook say "is done"          # speaks: "myproject is done"

> echo 'APP_NAME=Hermes' > .env
> ClaudeHook say "needs attention"  # speaks: "Hermes needs attention"

> ClaudeHook -D say "is done"       # --DRY_RUN: prints instead of speaking
```

## 🔔 `sound` — quick status beeps

`ClaudeHook sound <success|warning|error>` plays a short status sound. It tries
`afplay` with the built-in macOS system sounds, then `paplay` / `aplay` with the
freedesktop sound theme on Linux, and finally falls back to ASCII `BEL`
characters (1 beep for `success`, 2 for `warning`, 3 for `error`).

```bash
> ClaudeHook sound success          # plays Glass.aiff / complete.oga / 1 beep
> ClaudeHook sound warning          # plays Ping.aiff  / dialog-warning.oga / 2 beeps
> ClaudeHook sound error            # plays Basso.aiff / dialog-error.oga   / 3 beeps

> ClaudeHook -D sound success       # --DRY_RUN: prints the kind instead of playing
```

Aliases: `ok` → `success`, `warn` → `warning`, `fail` / `err` → `error`.

## 🏷️ `title` — decorate the terminal tab title

`ClaudeHook title <status>` rewrites the terminal tab/window title to
`<emoji> <app_name>` so you can spot the alerting tab at a glance — useful in
IDEs like PhpStorm where multiple terminal tabs share a window and only one
shows content at a time.

| status      | emoji | aliases                       |
|-------------|-------|-------------------------------|
| `success`   | ✅    | `ok`                          |
| `warning`   | ⚠️    | `warn`                        |
| `error`     | ⛔    | `fail`, `err`, `failure`      |
| `attention` | 🔔    | `bell`, `alert`               |
| `info`      | ℹ️    | —                             |
| `clear`     | (none) | `reset`, `off`, `none`       |

```bash
> ClaudeHook title attention        # tab title → "🔔 myproject"
> ClaudeHook title success          # tab title → "✅ myproject"
> ClaudeHook title clear            # tab title → "myproject"

> ClaudeHook -D title success       # --DRY_RUN: prints the would-be title
```

The OSC escape is written to `/dev/tty`, so it reaches the terminal even when
Claude Code captures the hook's stdout. Most shell prompts re-set the title on
the next command, so the decoration naturally clears when you start typing
again.

## 📨 `notify` — desktop notification

`ClaudeHook notify "<message>"` shows an OS desktop notification with title
`<app_name>` and body `<message>`, using `notify-send` (Linux) or `osascript`
(macOS). Clicking the notification usually focuses the originating app.

```bash
> ClaudeHook notify "is done"       # notification: "myproject" / "is done"
> ClaudeHook -D notify "is done"    # --DRY_RUN: prints "myproject: is done"
```

## 🚀 Installation

with [basher](https://github.com/basherpm/basher)

	$ basher install pforret/ClaudeHook

or with `git`

	$ git clone https://github.com/pforret/ClaudeHook.git
	$ cd ClaudeHook

## 📝 Acknowledgements

* script created with [bashew](https://github.com/pforret/bashew)

&copy; 2026 Peter Forret
