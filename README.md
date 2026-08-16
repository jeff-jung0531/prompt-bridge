# Prompt Bridge

Tiny free macOS helper for long-paste failures in AI chat apps.

Some Claude clients have converted long pasted text into an attachment/document
object that reaches the model empty. See related reports:
[anthropics/claude-code#77946](https://github.com/anthropics/claude-code/issues/77946),
[anthropics/claude-code#82590](https://github.com/anthropics/claude-code/issues/82590).

Prompt Bridge avoids that fragile paste path by turning copied long text into a
real `.md` file, copying the file, and letting you attach it with `Cmd+V`.

## What It Does

1. Copy long text.
2. Click **Make File**.
3. Paste the copied file into Claude with `Cmd+V`, or click **Open Finder** and
   drag the file in.

Files are kept in the app cache:

```text
~/Library/Caches/Prompt Bridge
```

The app keeps the newest files and automatically removes older handoff files.

## Permissions

Prompt Bridge only reads the current clipboard when you click **Make File** and
then copies the generated file back to the clipboard. It does not need browser,
terminal, input monitoring, or accessibility permissions.

## Download

The macOS app is free and open source.

Release zip name:

```text
prompt-bridge-macos.zip
```

The app is ad-hoc signed for local distribution. If macOS blocks the first
launch, use **Open** from Finder's context menu.

## Build

```bash
./scripts/build_macos_app.sh
```

The built app and zip are written to `dist/`.

## Why File Instead Of Plain Paste?

If your AI app now keeps long pasted text in the message body, you probably do
not need this tool. It is a fallback for environments where long paste handling
still produces an empty attachment.
