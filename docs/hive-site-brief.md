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
Claude Code, Codex, Gemini CLI 같은 AI CLI에 한글/CJK 프롬프트를 한 글자씩 직접 치지 않고 더 안정적으로 넘기도록 도와주는 무료 macOS 보조 앱입니다.
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
https://github.com/jeff-jung0531/ime-safe-ai-cli-terminal/releases/download/v0.1.20/ime-safe-ai-cli-terminal-macos.zip
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
Use Claude Code, Codex, Gemini CLI, and Qwen Code with fewer missing characters, duplicate inputs, and composition glitches on macOS.
```

Korean version:

```text
Claude Code, Codex, Gemini CLI에 한글 프롬프트를 더 안정적으로 넘기도록 도와주는 macOS 보조 앱입니다.
```

## Feature Bullets

- Guided Mac app flow
- Checks and uses tmux automatically
- Lets users choose the working folder for new CLI sessions
- Supports Claude Code, Codex, Gemini CLI, and Qwen Code by default
- Sends already-committed IME text through bracketed paste
- Helps avoid fragile character-by-character terminal input
- Shows local Protected counters for safe sends, committed characters, lines, and bytes
- Returns focus to Terminal after Send by default
- Keeps interactive AI CLI sessions intact
- No global keyboard interception by default
- No Accessibility or Input Monitoring permission required for the current helper

## What It Helps With

- Korean/IME composition glitches
- Missing or duplicated prompt characters
- Broken spaces during composition
- Long prompt entry into AI CLI tools
- Accidental early submission while text is still being composed

## Evidence Language

Recommended claim:

```text
Mitigates known Korean/CJK/IME input glitches in interactive AI CLI tools by sending already-committed IME text through tmux bracketed paste instead of fragile character-by-character terminal input.
```

Korean:

```text
한글/CJK/IME 조합이 끝난 글을 터미널에 한 글자씩 직접 치지 않고 tmux bracketed paste로 한 번에 넘겨, 대화형 AI CLI에서 깨지기 쉬운 입력 과정을 줄입니다.
```

Protected counter wording:

```text
Protected counters show how many successful sends, committed characters, lines, and bytes used the safe path in the current app run. They measure avoided direct terminal typing, not the exact number of typos that would have happened.
```

Korean:

```text
Protected 카운터는 이번 앱 실행 중 터미널에 직접 치지 않고 앱으로 넘긴 횟수, 문자 수, 줄 수, 바이트 수를 보여줍니다. 실제로 몇 개의 오타가 날 뻔했는지를 정확히 안다는 뜻은 아닙니다.
```

## What It Does Not Claim

- It does not fix all macOS keyboard problems.
- It does not repair hardware keyboard issues.
- It does not fix terminal rendering bugs.
- It does not fix every Claude/Codex/Gemini internal bug.
- It does not correct typos already present in the copied text.
- Protected counters do not prove exact avoided typo counts.
- It is not a full terminal replacement yet.

## Current Build Reality

Current v0.1 app shape:

- A lightweight macOS `.app` wrapper around local helper scripts.
- Users can select multiple installed AI CLI targets and start them together.
- New sessions start in the chosen working folder, not Finder's `/` launch directory.
- After successful Start, the Active screen remains visible.
- After successful Send, the app can hide so Terminal keeps focus.
- Opens app-style macOS prompts for target selection and actions.
- Keeps the main UI simple: target checkboxes, Start Selected, Send Clipboard,
  Details.
- Start Selected is one-time setup per target; already active sessions stay
  active and are not opened again.
- Once every selected session is active, Start Selected changes to Started and
  is disabled.
- The target list visibly marks each tool as active, not running, or missing,
  with a readiness summary above the checkboxes.
- Active state exposes Send Clipboard and Stop Selected. Stopping sessions
  returns the app to the start-ready state.
- Active state should feel like a small VPN-style status screen, including
  elapsed active duration and an always-available stop control.
- Main UI now leads with a status panel: Ready or Active, plus active elapsed
  duration.
- Clipboard sending works from the GUI app because the paste helper falls back
  to pbpaste unless `--stdin` is explicitly requested.
- The app now creates tmux sessions directly and only then opens Terminal attach
  windows, so active state reflects actual session creation.
- Includes only major tools with direct IME/input-risk evidence by default.
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
4. Supported tools: Claude Code, Codex, Gemini CLI, Qwen Code
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
