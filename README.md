# IME Safe AI CLI Terminal

한국어: 이 도구는 macOS의 전역 키보드 문제를 고치는 프로그램이 아닙니다.
Codex, Claude Code, Gemini CLI 같은 대화형 AI CLI 앞에서 CJK 입력이 깨질 때,
완성된 문장을 `tmux` bracketed paste로 주입하는 작은 우회책입니다.

English: This is not a global keyboard fixer. It is a tiny workaround for CJK
input glitches in interactive AI CLIs. It sends completed text into an existing
`tmux` session using bracketed paste, so the CLI receives a paste event instead
of fragile character-by-character IME input.

Important: this repository is the small fallback utility, not the final product
shape. The better long-term app is an IME-safe AI terminal/input layer where
users type normally and the app handles the fragile input path automatically.
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

## Install

```bash
brew install tmux
git clone <this-repo-url>
cd ai-cli-paste-shield
./install.sh
```

This repository intentionally ships as a shell script. No Swift app, no binary,
no Accessibility permission, no Input Monitoring permission.

## Downloadable App

For users who do not want to work from source, download the macOS app zip from
the GitHub Releases page:

```text
https://github.com/jeff-jung0531/ime-safe-ai-cli-terminal/releases/latest/download/ime-safe-ai-cli-terminal-macos.zip
```

Unzip it, open `IME Safe AI CLI Terminal.app`, then follow the guided prompts.
The app is a lightweight wrapper around the same local scripts in this
repository.

The release app is ad-hoc signed but not notarized. macOS may show a first-run
security warning for downloads outside the App Store.

## Guided Wizard

For non-developers, double-click:

```text
IME Safe AI CLI Terminal.app
```

The wizard walks through:

- checking `tmux`
- choosing Claude, Codex, or Gemini
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
