import AppKit
import Foundation

struct CommandCandidate {
    let executable: String
    let args: [String]
}

struct Target {
    let id: String
    let label: String
    let session: String
    let candidates: [CommandCandidate]

    static let all: [Target] = [
        Target(id: "claude", label: "Claude Code", session: "claude", candidates: [
            CommandCandidate(executable: "claude", args: []),
            CommandCandidate(executable: "\(NSHomeDirectory())/.local/bin/claude", args: []),
        ]),
        Target(id: "codex", label: "Codex", session: "codex", candidates: [
            CommandCandidate(executable: "codex", args: []),
            CommandCandidate(executable: "/Applications/ChatGPT.app/Contents/Resources/codex", args: []),
        ]),
        Target(id: "gemini", label: "Gemini CLI", session: "gemini", candidates: [
            CommandCandidate(executable: "gemini", args: []),
            CommandCandidate(executable: "\(NSHomeDirectory())/.local/bin/gemini", args: []),
        ]),
        Target(id: "cursor", label: "Cursor Agent", session: "cursor", candidates: [
            CommandCandidate(executable: "cursor-agent", args: []),
            CommandCandidate(executable: "agent", args: []),
            CommandCandidate(executable: "\(NSHomeDirectory())/.local/bin/cursor-agent", args: []),
            CommandCandidate(executable: "\(NSHomeDirectory())/.local/bin/agent", args: []),
        ]),
        Target(id: "amp", label: "Amp", session: "amp", candidates: [
            CommandCandidate(executable: "amp", args: []),
            CommandCandidate(executable: "\(NSHomeDirectory())/.local/bin/amp", args: []),
        ]),
        Target(id: "amazon-q", label: "Amazon Q / Kiro", session: "amazon-q", candidates: [
            CommandCandidate(executable: "q", args: ["chat"]),
            CommandCandidate(executable: "kiro", args: []),
            CommandCandidate(executable: "\(NSHomeDirectory())/.local/bin/q", args: ["chat"]),
            CommandCandidate(executable: "\(NSHomeDirectory())/.local/bin/kiro", args: []),
        ]),
        Target(id: "opencode", label: "OpenCode", session: "opencode", candidates: [
            CommandCandidate(executable: "opencode", args: []),
            CommandCandidate(executable: "\(NSHomeDirectory())/.local/bin/opencode", args: []),
        ]),
        Target(id: "aider", label: "Aider", session: "aider", candidates: [
            CommandCandidate(executable: "aider", args: []),
            CommandCandidate(executable: "\(NSHomeDirectory())/.local/bin/aider", args: []),
        ]),
        Target(id: "qwen", label: "Qwen Code", session: "qwen", candidates: [
            CommandCandidate(executable: "qwen", args: []),
            CommandCandidate(executable: "qwen-code", args: []),
            CommandCandidate(executable: "\(NSHomeDirectory())/.local/bin/qwen", args: []),
            CommandCandidate(executable: "\(NSHomeDirectory())/.local/bin/qwen-code", args: []),
        ]),
    ]
}

struct ShellResult {
    let status: Int32
    let output: String
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appName = "IME Safe AI CLI Terminal"
    private let pathValue = "\(NSHomeDirectory())/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Applications/ChatGPT.app/Contents/Resources"

    private var window: NSWindow!
    private var targetPopup: NSPopUpButton!
    private var statusView: NSTextView!
    private var sendEnterCheckbox: NSButton!

    private var resourceURL: URL {
        Bundle.main.resourceURL ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        buildWindow()
        showWindow()
        refreshStatus()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow()
        refreshStatus()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func buildWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 430),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = appName
        window.center()

        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = content

        let title = NSTextField(labelWithString: appName)
        title.font = .systemFont(ofSize: 20, weight: .semibold)

        let subtitle = NSTextField(labelWithString: "Open and send input to multiple AI CLI tmux sessions safely.")
        subtitle.textColor = .secondaryLabelColor
        subtitle.font = .systemFont(ofSize: 13)

        targetPopup = NSPopUpButton()
        targetPopup.addItems(withTitles: Target.all.map(\.label))
        targetPopup.target = self
        targetPopup.action = #selector(refreshStatusAction)

        sendEnterCheckbox = NSButton(checkboxWithTitle: "Press Enter after sending", target: nil, action: nil)
        sendEnterCheckbox.state = .on

        let openButton = NSButton(title: "Open / Attach Selected", target: self, action: #selector(openSelectedAction))
        openButton.bezelStyle = .rounded

        let sendSelectedButton = NSButton(title: "Send to Selected", target: self, action: #selector(sendSelectedAction))
        sendSelectedButton.bezelStyle = .rounded

        let sendAllButton = NSButton(title: "Send to All Active", target: self, action: #selector(sendAllAction))
        sendAllButton.bezelStyle = .rounded

        let refreshButton = NSButton(title: "Refresh", target: self, action: #selector(refreshStatusAction))
        refreshButton.bezelStyle = .rounded

        let githubButton = NSButton(title: "GitHub", target: self, action: #selector(openGitHubAction))
        githubButton.bezelStyle = .rounded

        statusView = NSTextView()
        statusView.isEditable = false
        statusView.isSelectable = true
        statusView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        statusView.textColor = .labelColor
        statusView.backgroundColor = .textBackgroundColor

        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        scroll.documentView = statusView

        let headerStack = NSStackView(views: [title, subtitle])
        headerStack.orientation = .vertical
        headerStack.alignment = .leading
        headerStack.spacing = 4

        let targetLabel = NSTextField(labelWithString: "Target")
        let targetStack = NSStackView(views: [targetLabel, targetPopup, sendEnterCheckbox])
        targetStack.orientation = .horizontal
        targetStack.alignment = .centerY
        targetStack.spacing = 10

        let buttonStack = NSStackView(views: [openButton, sendSelectedButton, sendAllButton, refreshButton, githubButton])
        buttonStack.orientation = .horizontal
        buttonStack.alignment = .centerY
        buttonStack.spacing = 8

        let mainStack = NSStackView(views: [headerStack, targetStack, buttonStack, scroll])
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.orientation = .vertical
        mainStack.alignment = .leading
        mainStack.spacing = 14
        content.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            mainStack.topAnchor.constraint(equalTo: content.topAnchor, constant: 18),
            mainStack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),
            scroll.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 210),
            targetPopup.widthAnchor.constraint(equalToConstant: 170),
        ])
    }

    private func showWindow() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private var selectedTarget: Target {
        Target.all[targetPopup.indexOfSelectedItem]
    }

    @objc private func openSelectedAction() {
        openSession(selectedTarget)
        refreshStatus()
    }

    @objc private func sendSelectedAction() {
        sendClipboard(to: selectedTarget)
        refreshStatus()
    }

    @objc private func sendAllAction() {
        let activeTargets = Target.all.filter { hasSession($0.session) }
        if activeTargets.isEmpty {
            appendStatus("No active Claude/Codex/Gemini tmux sessions found.")
            return
        }
        for target in activeTargets {
            sendClipboard(to: target)
        }
        refreshStatus()
    }

    @objc private func refreshStatusAction() {
        refreshStatus()
    }

    @objc private func openGitHubAction() {
        NSWorkspace.shared.open(URL(string: "https://github.com/jeff-jung0531/ime-safe-ai-cli-terminal")!)
    }

    private func openSession(_ target: Target) {
        guard ensureTmux() else { return }
        guard let commandParts = detectCLI(target) else {
            appendStatus("\(target.label): command not found. Install or log in first.")
            return
        }

        let launchCommand = commandParts.map(shellQuote).joined(separator: " ")
        let command = "tmux new-session -A -s \(shellQuote(target.session)) \(launchCommand)"
        let script = """
        tell application "Terminal"
          activate
          do script "\(escapeAppleScript(command))"
        end tell
        """
        if runAppleScript(script) {
            appendStatus("Opened \(target.label) in tmux session '\(target.session)'.")
        }
    }

    private func sendClipboard(to target: Target) {
        guard ensureTmux() else { return }
        guard hasSession(target.session) else {
            appendStatus("\(target.label): no tmux session named '\(target.session)'. Open it first.")
            return
        }

        let pasteScript = resourceURL.appendingPathComponent("ai-cli-paste").path
        var args = [target.session]
        if sendEnterCheckbox.state == .on {
            args.append("--enter")
        }

        let result = runExecutable(pasteScript, args: args)
        let output = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.status == 0 {
            appendStatus("\(target.label): \(output.isEmpty ? "sent clipboard" : output)")
        } else {
            appendStatus("\(target.label): send failed\n\(output)")
        }
    }

    private func refreshStatus() {
        var lines: [String] = []
        lines.append("Status updated: \(DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium))")
        lines.append("")
        lines.append("tmux: \(runShell("command -v tmux").status == 0 ? "OK" : "missing")")
        lines.append("")

        let sessions = tmuxSessions()
        for target in Target.all {
            let cli = detectCLI(target) == nil ? "missing" : "OK"
            let session = sessions.contains(target.session) ? "active" : "not running"
            lines.append("\(target.label): command \(cli), session '\(target.session)' \(session)")
        }

        if !sessions.isEmpty {
            lines.append("")
            lines.append("All tmux sessions: \(sessions.joined(separator: ", "))")
        }

        setStatus(lines.joined(separator: "\n"))
    }

    private func ensureTmux() -> Bool {
        if runShell("command -v tmux").status == 0 {
            return true
        }

        if runShell("command -v brew").status != 0 {
            appendStatus("tmux is required, but Homebrew was not found. Install Homebrew first, then run: brew install tmux")
            return false
        }

        let alert = NSAlert()
        alert.messageText = "Install tmux?"
        alert.informativeText = "tmux is required to keep AI CLI sessions open safely."
        alert.addButton(withTitle: "Install tmux")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return false }

        let script = """
        tell application "Terminal"
          activate
          do script "brew install tmux"
        end tell
        """
        _ = runAppleScript(script)
        appendStatus("A Terminal window is installing tmux. Try again after installation finishes.")
        return false
    }

    private func detectCLI(_ target: Target) -> [String]? {
        firstExistingCommand(target.candidates)
    }

    private func firstExistingCommand(_ candidates: [CommandCandidate]) -> [String]? {
        for candidate in candidates {
            if candidate.executable.contains("/") {
                if FileManager.default.isExecutableFile(atPath: candidate.executable) {
                    return [candidate.executable] + candidate.args
                }
            } else {
                let result = runShell("command -v \(shellQuote(candidate.executable))")
                if result.status == 0 {
                    let value = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !value.isEmpty { return [value] + candidate.args }
                }
            }
        }
        return nil
    }

    private func hasSession(_ name: String) -> Bool {
        runShell("tmux has-session -t \(shellQuote(name))").status == 0
    }

    private func tmuxSessions() -> [String] {
        let result = runShell("tmux list-sessions -F '#S'")
        guard result.status == 0 else { return [] }
        return result.output
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func runAppleScript(_ source: String) -> Bool {
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error {
            appendStatus("AppleScript error: \(error)")
            return false
        }
        return true
    }

    private func runShell(_ command: String) -> ShellResult {
        runExecutable("/bin/zsh", args: ["-lc", "export PATH=\(shellQuote(pathValue)); \(command)"])
    }

    private func runExecutable(_ executable: String, args: [String]) -> ShellResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = args
        process.environment = [
            "PATH": pathValue,
            "HOME": NSHomeDirectory(),
            "LANG": "en_US.UTF-8",
            "LC_ALL": "en_US.UTF-8",
        ]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return ShellResult(status: process.terminationStatus, output: output)
        } catch {
            return ShellResult(status: 1, output: error.localizedDescription)
        }
    }

    private func appendStatus(_ message: String) {
        let previous = statusView.string
        let joined = previous.isEmpty ? message : previous + "\n\n" + message
        setStatus(joined)
    }

    private func setStatus(_ message: String) {
        statusView.string = message
        statusView.scrollToEndOfDocument(nil)
    }

    private func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private func escapeAppleScript(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
