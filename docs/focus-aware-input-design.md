# Focus-aware Input Design

This project started as a tiny tmux paste workaround. That is useful, but it is
not the right long-term product experience. A good tool should not make users
remember rituals, copy prompts by hand, or think about transport mechanics.

The real product goal is:

> Let users type normally while the app quietly keeps AI CLI input safe.

## UX Goal

Users should not need to know what tmux, bracketed paste, PTY, or IME composition
means.

The desired flow:

1. Open the helper app.
2. Choose Claude, Codex, or Gemini.
3. Type normally.
4. The app handles Korean/English composition, spaces, Enter, Esc, arrows, and
   control keys safely.

## Three Possible Architectures

### 1. Focus-aware overlay for existing Terminal apps

The helper watches the focused macOS app/window. If Terminal, iTerm2, Warp, or
Ghostty is focused and the active session appears to be Claude, Codex, or Gemini,
the helper can offer a safe input overlay.

Pros:

- Works with the user's existing terminal.
- Small migration cost.
- No need to replace the terminal UI.

Cons:

- Truly transparent behavior requires Accessibility and possibly Input
  Monitoring permissions.
- Blocking or rewriting live key events can interfere with IME composition.
- Shortcut handling remains fragile because the terminal still owns part of the
  interaction.

Recommended use:

- Optional helper mode, not the default foundation.
- Detect focus and offer a composer or hotkey.
- Avoid global key rewriting as the primary mechanism.

### 2. IME-safe AI terminal wrapper

The app owns the terminal session. It launches Claude, Codex, or Gemini inside a
PTY, renders output, and handles input through native macOS text controls before
sending committed text and control sequences to the PTY.

Pros:

- Best user experience.
- No global keyboard interception.
- The app can distinguish text composition from control keys.
- The user simply types in the app.
- Easier to test and explain.

Cons:

- More engineering work than a shell script.
- Terminal rendering, resize behavior, colors, mouse support, and alternate
  screen handling must be implemented or delegated to a terminal component.

Recommended use:

- Main product direction.
- Start with a minimal single-window app for one AI CLI.
- Add Claude/Codex/Gemini launch presets after the PTY path works.

### 3. Global key event interception

The app uses CGEventTap/Input Monitoring to watch or rewrite keyboard events
system-wide.

Pros:

- Can theoretically work across existing apps.
- Can feel automatic when it works.

Cons:

- High privacy and trust cost.
- Sensitive macOS permissions.
- Can create the same class of IME bugs it is trying to fix.
- Difficult to make reliable across keyboard layouts, input methods, terminal
  apps, and CLI TUIs.

Recommended use:

- Avoid as the default product path.
- Consider only for diagnostic mode or explicit advanced experiments.

## Recommendation

Build toward architecture 2: an IME-safe AI terminal wrapper.

Keep the current tmux/bracketed-paste script as:

- a fallback
- a proof of transport
- a no-permission escape hatch
- a small open-source utility

But do not position the final app as a paste tool. The final app should be an
input-safe AI CLI terminal.

## MVP App Scope

The first real app should do only this:

- Native macOS window
- Target picker: Claude, Codex, Gemini
- Launch selected CLI in a PTY
- Render terminal output
- Native text input path for composed text
- Separate handling for Enter, Esc, Ctrl+C, arrows, and paste
- Session status and restart

Non-goals for the first app:

- No global key interception
- No general-purpose terminal replacement
- No plugin system
- No account management
- No cloud sync

## Naming Shift

Avoid names centered on paste. Better names:

- CLI Input Shield
- IME Safe Terminal
- AI CLI Input Guard
- SafeCLI Input

The implementation may still use paste-like PTY transport in some cases, but
the user-facing product is safe input, not manual paste.
