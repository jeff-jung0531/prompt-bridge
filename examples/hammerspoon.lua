-- Paste the macOS clipboard into an existing tmux session named "claude".
hs.hotkey.bind({"cmd", "alt"}, "return", function()
  hs.execute("ai-cli-paste claude --enter", true)
end)
