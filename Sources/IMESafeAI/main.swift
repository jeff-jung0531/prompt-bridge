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
    private var targetButtons: [String: NSButton] = [:]
    private var statusView: NSTextView!
    private var sendEnterCheckbox: NSButton!
    private var detailsContainer: NSScrollView!
    private var detailsButton: NSButton!
    private var detailsHeightConstraint: NSLayoutConstraint!
    private var detailsVisible = false

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
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 260),
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

        let subtitle = NSTextField(labelWithString: "Choose one or more AI CLIs, start them safely, then send clipboard text when needed.")
        subtitle.textColor = .secondaryLabelColor
        subtitle.font = .systemFont(ofSize: 13)

        sendEnterCheckbox = NSButton(checkboxWithTitle: "Press Enter after sending", target: nil, action: nil)
        sendEnterCheckbox.state = .on

        let openButton = NSButton(title: "Start Selected", target: self, action: #selector(openSelectedAction))
        openButton.bezelStyle = .rounded
        openButton.keyEquivalent = "\r"

        let sendSelectedButton = NSButton(title: "Send Clipboard", target: self, action: #selector(sendSelectedAction))
        sendSelectedButton.bezelStyle = .rounded

        detailsButton = NSButton(title: "Details", target: self, action: #selector(toggleDetailsAction))
        detailsButton.bezelStyle = .rounded

        statusView = NSTextView()
        statusView.isEditable = false
        statusView.isSelectable = true
        statusView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        statusView.textColor = .labelColor
        statusView.backgroundColor = .textBackgroundColor

        detailsContainer = NSScrollView()
        detailsContainer.hasVerticalScroller = true
        detailsContainer.borderType = .bezelBorder
        detailsContainer.documentView = statusView
        detailsContainer.isHidden = true

        let headerStack = NSStackView(views: [title, subtitle])
        headerStack.orientation = .vertical
        headerStack.alignment = .leading
        headerStack.spacing = 4

        let targetLabel = NSTextField(labelWithString: "Targets")
        targetLabel.font = .systemFont(ofSize: 13, weight: .medium)

        let targetGrid = NSGridView()
        targetGrid.rowSpacing = 7
        targetGrid.columnSpacing = 14
        targetGrid.translatesAutoresizingMaskIntoConstraints = false

        for rowIndex in 0..<3 {
            var rowViews: [NSView] = []
            for columnIndex in 0..<3 {
                let index = rowIndex * 3 + columnIndex
                if index < Target.all.count {
                    let target = Target.all[index]
                    let button = NSButton(checkboxWithTitle: target.label, target: self, action: #selector(refreshStatusAction))
                    button.state = shouldSelectByDefault(target) ? .on : .off
                    targetButtons[target.id] = button
                    rowViews.append(button)
                } else {
                    rowViews.append(NSView())
                }
            }
            targetGrid.addRow(with: rowViews)
        }

        let targetStack = NSStackView(views: [targetLabel, targetGrid, sendEnterCheckbox])
        targetStack.orientation = .vertical
        targetStack.alignment = .leading
        targetStack.spacing = 8

        let buttonStack = NSStackView(views: [openButton, sendSelectedButton, detailsButton])
        buttonStack.orientation = .horizontal
        buttonStack.alignment = .centerY
        buttonStack.spacing = 8

        let hint = NSTextField(labelWithString: "Check one or more tools. Start opens sessions; Send Clipboard sends to all checked active sessions.")
        hint.textColor = .secondaryLabelColor
        hint.font = .systemFont(ofSize: 12)

        let mainStack = NSStackView(views: [headerStack, targetStack, buttonStack, hint, detailsContainer])
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
            detailsContainer.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
        ])
        detailsHeightConstraint = detailsContainer.heightAnchor.constraint(equalToConstant: 0)
        detailsHeightConstraint.isActive = true
    }

    private func shouldSelectByDefault(_ target: Target) -> Bool {
        ["claude", "codex", "gemini"].contains(target.id) && detectCLI(target) != nil
    }

    private func showWindow() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private var selectedTargets: [Target] {
        Target.all.filter { targetButtons[$0.id]?.state == .on }
    }

    @objc private func openSelectedAction() {
        let targets = selectedTargets
        guard !targets.isEmpty else {
            appendStatus("Select at least one target.")
            showDetails()
            return
        }
        for target in targets {
            openSession(target)
        }
        refreshStatus()
    }

    @objc private func sendSelectedAction() {
        let targets = selectedTargets
        guard !targets.isEmpty else {
            appendStatus("Select at least one target.")
            showDetails()
            return
        }
        for target in targets {
            sendClipboard(to: target)
        }
        refreshStatus()
    }

    @objc private func refreshStatusAction() {
        refreshStatus()
    }

    @objc private func toggleDetailsAction() {
        detailsVisible.toggle()
        detailsContainer.isHidden = !detailsVisible
        detailsButton.title = detailsVisible ? "Hide Details" : "Details"
        detailsHeightConstraint.constant = detailsVisible ? 130 : 0
        window.setContentSize(NSSize(width: window.frame.width, height: detailsVisible ? 390 : 260))
        refreshStatus()
    }

    private func openSession(_ target: Target) {
        guard ensureTmux() else { return }
        guard let commandParts = detectCLI(target) else {
            appendStatus("\(target.label): command not found. Install or log in first.")
            showDetails()
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
            showDetails()
        }
    }

    private func sendClipboard(to target: Target) {
        guard ensureTmux() else { return }
        guard hasSession(target.session) else {
            appendStatus("\(target.label): no tmux session named '\(target.session)'. Open it first.")
            showDetails()
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
        showDetails()
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
            showDetails()
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
        showDetails()
        return false
    }

    private func showDetails() {
        guard !detailsVisible else { return }
        detailsVisible = true
        detailsContainer.isHidden = false
        detailsButton.title = "Hide Details"
        detailsHeightConstraint.constant = 130
        window.setContentSize(NSSize(width: window.frame.width, height: 390))
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
