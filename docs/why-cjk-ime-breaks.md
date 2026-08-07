# Why CJK Input Breaks in AI CLIs

한국어: 이 문서는 문제의 책임을 특정 앱 하나에 돌리기 위한 글이 아닙니다. 같은
증상이 여러 AI CLI에서 반복되는 이유를 설명하고, 왜 이 저장소가 키보드 후킹이
아니라 bracketed paste 우회를 선택하는지 정리합니다.

English: This note is not about blaming one app. It explains why similar CJK
input glitches appear across multiple AI CLIs, and why this repository chooses a
bracketed paste workaround instead of global keyboard interception.

## The Stack

Interactive AI CLIs often sit on top of four layers:

- macOS IME composition
- terminal input and escape sequences
- PTY transport
- a terminal UI framework

Latin character input often looks like a stream of simple key events. CJK input
does not. Korean, Japanese, and Chinese text can involve composition state,
candidate selection, mode switching, partial commits, and Enter/Space semantics
that are not equivalent to ordinary keypresses.

When a terminal UI treats those events as simple keys, symptoms can appear:

- characters disappear
- characters duplicate
- spaces are lost
- composition is committed too early
- Enter submits before the user intended it
- shortcuts behave differently while an IME is active

## Why Not CGEventTap

Global key interception can make the problem larger. It requires sensitive macOS
permissions, can interfere with composition, and changes the input path for all
apps. For this use case, adding another keyboard hook is the wrong kind of power.

## Why Bracketed Paste

Bracketed paste changes the contract. The CLI receives a completed text block as
paste input, not a fragile stream of composing key events. That preserves the
interactive AI CLI session while avoiding the most failure-prone part of the
input path.

This does not fix every problem. It cannot repair rendering bugs or shortcut
bugs inside a CLI. It simply removes the CJK composition path from long prompt
entry, which is usually where the pain is worst.

## Intended Lifetime

This workaround should become unnecessary if upstream CLIs and TUI frameworks
handle IME composition well. If that happens, the right outcome is to archive
this repository and point users to the upstream fixes.
