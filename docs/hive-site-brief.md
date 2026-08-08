# Hive Site Brief

## Product Positioning

User-facing product name:

```text
IME Safe AI CLI Terminal
```

Short description:

```text
A macOS helper app for safer IME input in major AI CLI tools.
```

Plain-language Korean description:

```text
Claude Code, Codex, Gemini CLI 등 주요 AI CLI에서 한글/IME 입력이 누락되거나 중복되거나 한영 전환 중 꼬이는 문제를 줄여주는 macOS용 보조 앱입니다.
```

Important positioning:

- Do not present it as a global keyboard fixer.
- Do not present it as a paste utility.
- Present it as an app-like guided helper for safer AI CLI input.
- The internal transport may use tmux/bracketed paste, but users should not need
  to understand or manually manage that.

## Primary Audience

- Korean, Japanese, Chinese, Vietnamese, and other IME users who use AI CLI tools.
- Non-developers using Claude Code, Codex, or Gemini CLI through Terminal.
- Developers who are stressed by missing characters, duplicated keys, broken
  spaces, or accidental Enter while composing IME text.

## Website CTA

Primary CTA:

```text
Download for macOS
```

Secondary CTA:

```text
View on GitHub
```

Download asset:

```text
https://github.com/jeff-jung0531/ime-safe-ai-cli-terminal/releases/latest/download/ime-safe-ai-cli-terminal-macos.zip
```

GitHub repo:

```text
https://github.com/jeff-jung0531/ime-safe-ai-cli-terminal
```

Additional launch/social copy:

```text
docs/share-kit.md
```

## Suggested Hero Copy

Headline:

```text
Safer Korean and IME input for AI CLIs
```

Subheadline:

```text
Use Claude Code, Codex, and Gemini CLI with fewer missing characters, duplicate inputs, and composition glitches on macOS.
```

Korean version:

```text
Claude Code, Codex, Gemini CLI에서 한글 입력이 꼬이는 스트레스를 줄여주는 macOS 보조 앱입니다.
```

## Feature Bullets

- Guided Mac app flow
- Checks and uses tmux automatically
- Supports multiple AI CLI targets, including Claude Code, Codex, Gemini CLI,
  Cursor Agent, Amp, Amazon Q/Kiro, OpenCode, Aider, and Qwen Code
- Helps avoid fragile character-by-character IME input
- Keeps interactive AI CLI sessions intact
- No global keyboard interception by default
- No Accessibility or Input Monitoring permission required for the current helper

## What It Helps With

- Korean/IME composition glitches
- Missing or duplicated prompt characters
- Broken spaces during composition
- Long prompt entry into AI CLI tools
- Accidental early submission while text is still being composed

## What It Does Not Claim

- It does not fix all macOS keyboard problems.
- It does not repair hardware keyboard issues.
- It does not fix terminal rendering bugs.
- It does not fix every Claude/Codex/Gemini internal bug.
- It is not a full terminal replacement yet.

## Current Build Reality

Current v0.1 app shape:

- A lightweight macOS `.app` wrapper around local helper scripts.
- Opens app-style macOS prompts for target selection and actions.
- Keeps the main UI simple: target picker, Start, Send Clipboard, Details.
- Opens Terminal only when launching the selected AI CLI session.
- Uses local-only scripts and tmux.
- Ad-hoc signed, not Apple-notarized yet.

Website should mention:

```text
macOS may show a first-run security warning because this early build is not notarized yet.
```

Avoid saying:

```text
Install once and all keyboard problems disappear.
```

Better:

```text
This early helper reduces common IME input failures in AI CLI workflows by guiding input through a safer session path.
```

## Future Direction

The long-term product should become a true app-like IME-safe AI CLI terminal:

- Native macOS window
- Target picker for Claude, Codex, Gemini
- Built-in PTY session
- IME-safe text input path
- Separate handling for Enter, Esc, Ctrl+C, arrows, and paste
- No manual copy/paste ritual for users

The current GitHub project should be framed as:

```text
Early open-source helper and design foundation for IME-safe AI CLI input.
```

## Suggested Page Sections

1. Hero: problem and download CTA
2. Why this exists: AI CLI tools often mishandle IME composition
3. How it works for users: open app, choose target, follow wizard
4. Supported tools: Claude Code, Codex, Gemini CLI, Cursor Agent, Amp, Amazon Q/Kiro, OpenCode, Aider, Qwen Code
5. Download + GitHub
6. Limitations and safety notes
7. Future native app direction

## Tone

Use practical, low-hype language:

- "reduces"
- "helps"
- "safer input path"
- "early helper"
- "open-source"

Avoid overpromising:

- "fixes all keyboard issues"
- "perfect IME support"
- "works everywhere"
- "no more input bugs forever"
