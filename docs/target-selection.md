# Target Selection

This app should not include every popular AI CLI just because it is popular.
The rule is:

```text
Major AI CLI + direct IME/input-risk evidence
```

## Included by Default

| Tool | Why included |
| --- | --- |
| Claude Code | Multiple public Korean/CJK/IME issues report misplaced composition, invisible composition, character loss, and duplicate behavior. |
| Gemini CLI | Public parent issue and duplicates track Korean/Japanese IME typing, dropped characters, and composition display problems. |
| Codex | Public Codex issue exists for Korean IME preedit behavior, and the user has observed similar input instability locally. |
| Qwen Code | Qwen Code is terminal-agent style, adapted from Gemini CLI lineage, and has recent public input issues such as missing spacebar input. |

## Watchlist

These are major or relevant, but not included by default yet:

| Tool | Reason not included yet |
| --- | --- |
| Cursor Agent | Cursor terminal/IME issues exist, but clear Cursor Agent CLI-specific IME evidence is weaker. |
| Amp | Major CLI, but no direct matching IME/input issue found yet. |
| Amazon Q / Kiro | Major CLI, but no direct matching IME/input issue found yet. |
| OpenCode | Relevant CLI/desktop tool, but no direct matching terminal IME issue found yet. |
| Aider | Major terminal coding assistant, but no direct matching IME/input issue found yet. |
| GitHub Copilot CLI | Direct CJK/IME issue evidence exists, but command/session behavior needs a separate implementation pass before inclusion. |

## Add Criteria

Add a new target only when at least one is true:

- There is a public issue showing CJK/IME composition, key drop, duplicate input,
  spacebar, or Enter/preedit failure in that specific CLI.
- The tool is clearly built on a CLI/TUI stack already shown to reproduce the
  issue, and users report the same symptoms.
- A local user test reproduces the issue and the tool is common enough to matter.

Do not add targets solely because they are popular.
