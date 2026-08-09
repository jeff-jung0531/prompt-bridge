# Mac App Store Readiness

Current decision: keep the app free, but do not submit the current helper build
to the Mac App Store as-is.

## Why

The current app is useful as a free open-source download, but its core behavior
depends on desktop automation and external command-line tools:

- starts and checks `tmux` sessions
- opens Terminal with AppleScript
- sends clipboard text through a bundled shell helper
- offers a Homebrew-based `tmux` install path when `tmux` is missing
- intentionally leaves user-started `tmux` sessions running until the user stops them

Those choices are reasonable for a GitHub-distributed developer helper, but they
create Mac App Store review risk.

Apple's Mac App Store requirements say apps should be sandboxed, self-contained,
single app bundles, and should not install code or resources in shared locations.
They also warn against spawning processes that continue after the user quits the
app, and against downloading, installing, or executing code that changes app
functionality.

Reference:

- https://developer.apple.com/app-store/review/guidelines/

## App Store-Safe Direction

If this becomes a Mac App Store app, make a separate App Store edition instead
of submitting the current helper unchanged.

Recommended scope:

- no Homebrew install flow
- no bundled shell installer
- no hidden global keyboard hooks
- no claims about fixing keyboard hardware
- clear in-app explanation that the app helps move already-entered text into AI CLI tools
- explicit user action for every session start and stop
- App Sandbox enabled
- user-selected folder access through security-scoped bookmarks if file access is needed
- review notes that explain Terminal/tmux integration plainly

Distribution plan:

- GitHub release: full helper for technical users
- Mac App Store: simplified free edition only if the sandboxed behavior can be made review-friendly

