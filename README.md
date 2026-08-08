# IME Safe AI CLI Terminal

한국어: 이 도구는 macOS의 전역 키보드 문제를 고치는 프로그램이 아닙니다.
Codex, Claude Code, Gemini CLI 같은 대화형 AI CLI 앞에서 CJK 입력이 깨질 때,
완성된 문장을 `tmux` bracketed paste로 주입하는 작은 우회책입니다.

English: This is not a global keyboard fixer. It is a tiny workaround for CJK
input glitches in interactive AI CLIs. It sends completed text into an existing
`tmux` session using bracketed paste, so the CLI receives a paste event instead
of fragile character-by-character IME input.

Important: this repository is the small fallback utility and early app shell,
not the final product shape. The better long-term app is an IME-safe AI
terminal/input layer where users type normally and the app handles the fragile
input path automatically.
See [`docs/focus-aware-input-design.md`](docs/focus-aware-input-design.md).

## Why

Some AI CLIs run inside terminal UIs where macOS IME composition, terminal input,
PTY handling, and the TUI framework can disagree. The symptoms are familiar:

- missing or duplicated characters
- broken spaces
- Korean/English switching glitches
- accidental Enter while a composition is still active
- long prompts becoming painful to type directly

The safest practical workaround is:

1. Write the prompt somewhere stable.
2. Copy it.
3. Paste it into the existing interactive CLI session as bracketed paste.
4. Send Enter only when explicitly requested.

That keeps the important interactive loop intact: approvals, plan mode, slash
commands, interrupts, tool permissions, and multi-turn context.

## Download for macOS

Most users should start with the macOS app:

```text
https://github.com/jeff-jung0531/ime-safe-ai-cli-terminal/releases/download/v0.1.17/ime-safe-ai-cli-terminal-macos.zip
```

Unzip it, open `IME Safe AI CLI Terminal.app`, choose the AI CLI tools you use,
and follow the guided flow. The app can check whether `tmux` is available and
offer an install path if it is missing.

The release app is ad-hoc signed but not notarized. macOS may show a first-run
security warning for downloads outside the App Store.

## Source Install

Developers can also use the underlying script directly:

```bash
brew install tmux
git clone https://github.com/jeff-jung0531/ime-safe-ai-cli-terminal.git
cd ime-safe-ai-cli-terminal
./install.sh
```

The current helper does not request Accessibility permission or Input
Monitoring permission.

## Guided Wizard

For non-developers, double-click:

```text
IME Safe AI CLI Terminal.app
```

The wizard walks through:

- checking `tmux`
- choosing Claude Code, Codex, Gemini CLI, or Qwen Code
- opening the selected CLI inside a named tmux session
- pasting your copied prompt into that session

If `tmux` is missing, the wizard shows an `Install tmux` button and installs it
with Homebrew. If `tmux` is already installed, it skips that step automatically.
To install it yourself first:

```bash
brew install tmux
```

## Quick Start

Start your AI CLI inside a named tmux session:

```bash
tmux new -s claude
claude
```

In another terminal, send your clipboard to that session:

```bash
./ai-cli-paste claude
```

By default this pastes without pressing Enter. To paste and submit:

```bash
./ai-cli-paste claude --enter
```

You can also target Codex or Gemini sessions:

```bash
tmux new -s codex
codex

./ai-cli-paste codex --enter
```

```bash
tmux new -s gemini
gemini

./ai-cli-paste gemini --enter
```

## Usage

```bash
ai-cli-paste [session] [options]
```

Options:

- `--enter`: press Enter after paste
- `--no-bracket`: disable bracketed paste mode
- `--file PATH`: paste text from a file instead of the clipboard
- `--stdin`: paste text from stdin instead of the clipboard
- `--list`: list tmux sessions
- `--dry-run`: show what would happen without pasting
- `--help`: show help

Examples:

```bash
./ai-cli-paste claude
./ai-cli-paste claude --enter
./ai-cli-paste codex --file prompt.txt --enter
echo "요약해줘" | ./ai-cli-paste claude --stdin --enter
./ai-cli-paste --list
```

## Raycast / Hammerspoon

The useful product experience is a hotkey, not a big app.

Raycast script commands are in [`examples/`](examples/).

Minimal Raycast script command:

```bash
#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title Paste to Claude
# @raycast.mode silent

/path/to/ai-cli-paste claude --enter
```

Hammerspoon:

```lua
hs.hotkey.bind({"cmd", "alt"}, "return", function()
  hs.execute("/path/to/ai-cli-paste claude --enter", true)
end)
```

See also [`docs/why-cjk-ime-breaks.md`](docs/why-cjk-ime-breaks.md).
See the long-term app direction in
[`docs/focus-aware-input-design.md`](docs/focus-aware-input-design.md).

## What This Helps

- CJK IME composition glitches while typing into AI CLI text boxes
- missing or duplicated prompt characters
- space loss while composing Korean/Japanese/Chinese text
- long prompt transfer
- accidental early Enter during composition

## Keyboard Hardware Check

If the Space key also disappears while typing plain English text, for example
`a a a a` becomes `aaaa`, this helper is probably not the right fix for that
part of the problem. Check the external keyboard first:

- try a direct wired connection instead of Bluetooth, a hub, or a dongle
- press Space from the left, center, and right to find unstable spots
- inspect the spacebar stabilizer, keycap, and switch if the keyboard allows it
- compare with another keyboard if possible

This app can reduce fragile IME input paths in AI CLIs, but it cannot repair a
keyboard or connection that is not reliably sending Space.

## App Targets

The macOS helper intentionally includes only major AI CLI tools with direct
IME/input-risk evidence. Check one or more targets, start them, then send
clipboard text to the checked active sessions:

- Claude Code
- Codex
- Gemini CLI
- Qwen Code

Use `Start Selected` for the checked targets and `Send Clipboard` when you want
to transfer copied text to those checked sessions.

`Start Selected` is a one-time setup for each selected target. Once every
selected session is active, the button changes to `Started` and is disabled.
If a selected tmux session is already active, the app leaves it running and does
not open a second Terminal window for the same target.

The app also shows visible proof in the target list: each target is marked as
`(active)`, `(not running)`, or `(missing)`, with a readiness summary above the
checkboxes.

When every selected session is active, the app enters an active state: `Send
Clipboard` and `Stop Selected` are enabled, while `Start Selected` stays disabled
as `Started`. Stopping selected sessions returns the app to the start-ready
state.

The active state behaves like a lightweight VPN-style status screen: it shows
how long the selected sessions have been active and keeps the stop control
available until the user ends the sessions.

The main window is organized around this status panel first, so users can see
whether the helper is ready or active without opening details.

The app creates tmux sessions itself before opening Terminal attach windows, so
the visible active state reflects the real session state instead of assuming
Terminal successfully started it.

The macOS app sends clipboard text explicitly. The shell script reads stdin only
when `--stdin` is provided, so the GUI app still uses the macOS clipboard even
when launched with `/dev/null` stdin.

Watchlist, not included by default until there is clearer matching evidence:
Cursor Agent, Amp, Amazon Q/Kiro, OpenCode, Aider, GitHub Copilot CLI.

## Non-goals

- It does not fix global macOS keyboard behavior.
- It does not intercept keys with CGEventTap.
- It does not request Accessibility or Input Monitoring permission.
- It does not fix terminal rendering glitches.
- It does not fix CLI bugs around Ctrl+C, Ctrl+L, or shortcuts in IME mode.
- It does not replace Codex, Claude Code, or Gemini interactive sessions.

## Philosophy

This repository should stay small. If upstream CLIs fix IME handling properly,
this can be archived without drama. Until then, it is a practical pressure
release valve for users who need the interactive CLI loop but cannot trust
direct terminal typing.

## License

MIT
