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
    private let workingDirectoryDefaultsKey = "workingDirectory"
    private let hideAfterActionDefaultsKey = "hideAfterSuccessfulAction"

    private var window: NSWindow!
    private var targetButtons: [String: NSButton] = [:]
    private var statusView: NSTextView!
    private var openButton: NSButton!
    private var sendSelectedButton: NSButton!
    private var stopSelectedButton: NSButton!
    private var summaryLabel: NSTextField!
    private var modeLabel: NSTextField!
    private var durationLabel: NSTextField!
    private var modeDetailLabel: NSTextField!
    private var sendEnterCheckbox: NSButton!
    private var hideAfterActionCheckbox: NSButton!
    private var workingDirectoryLabel: NSTextField!
    private var detailsContainer: NSScrollView!
    private var detailsButton: NSButton!
    private var detailsHeightConstraint: NSLayoutConstraint!
    private var detailsVisible = false
    private var activeSince: Date?
    private var activeRefreshScheduled = false
    private var eventMessages: [String] = []
    private var commandCache: [String: [String]?] = [:]
    private var sessionCreatedTimes: [String: Date] = [:]

    private var resourceURL: URL {
        Bundle.main.resourceURL ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }

    private var workingDirectory: String {
        if let savedPath = UserDefaults.standard.string(forKey: workingDirectoryDefaultsKey),
           isDirectory(savedPath) {
            return savedPath
        }

        let cwd = FileManager.default.currentDirectoryPath
        if cwd != "/" {
            return cwd
        }
        return NSHomeDirectory()
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
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 410),
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

        let subtitle = NSTextField(labelWithString: "Start once, keep selected AI CLI sessions active, and stop them when finished.")
        subtitle.textColor = .secondaryLabelColor
        subtitle.font = .systemFont(ofSize: 13)

        sendEnterCheckbox = NSButton(checkboxWithTitle: "Press Enter after sending", target: nil, action: nil)
        sendEnterCheckbox.state = .on

        hideAfterActionCheckbox = NSButton(checkboxWithTitle: "Return focus after Start/Send", target: nil, action: nil)
        hideAfterActionCheckbox.state = UserDefaults.standard.object(forKey: hideAfterActionDefaultsKey) == nil
            ? .on
            : (UserDefaults.standard.bool(forKey: hideAfterActionDefaultsKey) ? .on : .off)
        hideAfterActionCheckbox.target = self
        hideAfterActionCheckbox.action = #selector(toggleHideAfterAction)

        openButton = NSButton(title: "Start Selected", target: self, action: #selector(openSelectedAction))
        openButton.bezelStyle = .rounded
        openButton.keyEquivalent = "\r"

        sendSelectedButton = NSButton(title: "Send Clipboard", target: self, action: #selector(sendSelectedAction))
        sendSelectedButton.bezelStyle = .rounded

        stopSelectedButton = NSButton(title: "Stop Selected", target: self, action: #selector(stopSelectedAction))
        stopSelectedButton.bezelStyle = .rounded

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

        modeLabel = NSTextField(labelWithString: "Ready")
        modeLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        durationLabel = NSTextField(labelWithString: "Not running")
        durationLabel.font = .monospacedDigitSystemFont(ofSize: 28, weight: .semibold)

        modeDetailLabel = NSTextField(labelWithString: "Select targets and start sessions.")
        modeDetailLabel.textColor = .secondaryLabelColor
        modeDetailLabel.font = .systemFont(ofSize: 12)

        let modeStack = NSStackView(views: [modeLabel, durationLabel, modeDetailLabel])
        modeStack.orientation = .vertical
        modeStack.alignment = .leading
        modeStack.spacing = 4

        let modeBox = NSBox()
        modeBox.title = ""
        modeBox.boxType = .custom
        modeBox.borderColor = .separatorColor
        modeBox.fillColor = .controlBackgroundColor
        modeBox.cornerRadius = 8
        modeBox.contentViewMargins = NSSize(width: 14, height: 12)
        modeBox.contentView?.addSubview(modeStack)
        modeStack.translatesAutoresizingMaskIntoConstraints = false
        if let boxContent = modeBox.contentView {
            NSLayoutConstraint.activate([
                modeStack.leadingAnchor.constraint(equalTo: boxContent.leadingAnchor),
                modeStack.trailingAnchor.constraint(equalTo: boxContent.trailingAnchor),
                modeStack.topAnchor.constraint(equalTo: boxContent.topAnchor),
                modeStack.bottomAnchor.constraint(equalTo: boxContent.bottomAnchor),
            ])
        }

        let targetLabel = NSTextField(labelWithString: "Targets")
        targetLabel.font = .systemFont(ofSize: 13, weight: .medium)

        let folderTitle = NSTextField(labelWithString: "Working Folder")
        folderTitle.font = .systemFont(ofSize: 13, weight: .medium)

        workingDirectoryLabel = NSTextField(labelWithString: "")
        workingDirectoryLabel.lineBreakMode = .byTruncatingMiddle
        workingDirectoryLabel.textColor = .secondaryLabelColor
        workingDirectoryLabel.font = .systemFont(ofSize: 12)
        updateWorkingDirectoryLabel()

        let chooseFolderButton = NSButton(title: "Choose Folder...", target: self, action: #selector(chooseWorkingDirectoryAction))
        chooseFolderButton.bezelStyle = .rounded

        let folderRow = NSStackView(views: [workingDirectoryLabel, chooseFolderButton])
        folderRow.orientation = .horizontal
        folderRow.alignment = .centerY
        folderRow.spacing = 8
        folderRow.distribution = .fill
        workingDirectoryLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let folderStack = NSStackView(views: [folderTitle, folderRow])
        folderStack.orientation = .vertical
        folderStack.alignment = .leading
        folderStack.spacing = 6

        summaryLabel = NSTextField(labelWithString: "Checking sessions...")
        summaryLabel.textColor = .secondaryLabelColor
        summaryLabel.font = .systemFont(ofSize: 12, weight: .medium)

        let targetGrid = NSGridView()
        targetGrid.rowSpacing = 7
        targetGrid.columnSpacing = 14
        targetGrid.translatesAutoresizingMaskIntoConstraints = false

        for rowIndex in 0..<2 {
            var rowViews: [NSView] = []
            for columnIndex in 0..<2 {
                let index = rowIndex * 2 + columnIndex
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

        let optionStack = NSStackView(views: [sendEnterCheckbox, hideAfterActionCheckbox])
        optionStack.orientation = .vertical
        optionStack.alignment = .leading
        optionStack.spacing = 4

        let targetStack = NSStackView(views: [folderStack, targetLabel, summaryLabel, targetGrid, optionStack])
        targetStack.orientation = .vertical
        targetStack.alignment = .leading
        targetStack.spacing = 8

        let buttonStack = NSStackView(views: [openButton, sendSelectedButton, stopSelectedButton, detailsButton])
        buttonStack.orientation = .horizontal
        buttonStack.alignment = .centerY
        buttonStack.spacing = 8

        let hint = NSTextField(labelWithString: "Active sessions stay running in the background until stopped.")
        hint.textColor = .secondaryLabelColor
        hint.font = .systemFont(ofSize: 12)

        let mainStack = NSStackView(views: [headerStack, modeBox, targetStack, buttonStack, hint, detailsContainer])
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
            modeBox.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            folderRow.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
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
        var allSucceeded = true
        for target in targets {
            allSucceeded = openSession(target) && allSucceeded
        }
        refreshStatus()
        if allSucceeded {
            returnFocusAfterSuccessfulAction()
        } else {
            showWindow()
        }
    }

    @objc private func sendSelectedAction() {
        let targets = selectedTargets
        guard !targets.isEmpty else {
            appendStatus("Select at least one target.")
            showDetails()
            return
        }
        var allSucceeded = true
        for target in targets {
            allSucceeded = sendClipboard(to: target) && allSucceeded
        }
        refreshStatus()
        if allSucceeded {
            returnFocusAfterSuccessfulAction()
        } else {
            showWindow()
        }
    }

    @objc private func stopSelectedAction() {
        let targets = selectedTargets
        guard !targets.isEmpty else {
            appendStatus("Select at least one target.")
            showDetails()
            return
        }

        let activeTargets = targets.filter { hasSession($0.session) }
        guard !activeTargets.isEmpty else {
            appendStatus("No selected active sessions to stop.")
            refreshStatus()
            return
        }

        let alert = NSAlert()
        alert.messageText = "Stop selected sessions?"
        alert.informativeText = "This will terminate \(activeTargets.map(\.label).joined(separator: ", "))."
        alert.addButton(withTitle: "Stop")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        for target in targets {
            guard hasSession(target.session) else { continue }
            let result = runShell("tmux kill-session -t \(shellQuote(target.session))")
            if result.status == 0 {
                sessionCreatedTimes.removeValue(forKey: target.session)
                activeSince = nil
                appendStatus("Stopped \(target.label) session '\(target.session)'.")
            } else {
                appendStatus("\(target.label): stop failed\n\(result.output.trimmingCharacters(in: .whitespacesAndNewlines))")
                showDetails()
            }
        }
        refreshStatus()
        showWindow()
    }

    @objc private func refreshStatusAction() {
        refreshStatus()
    }

    @objc private func toggleDetailsAction() {
        detailsVisible.toggle()
        detailsContainer.isHidden = !detailsVisible
        detailsButton.title = detailsVisible ? "Hide Details" : "Details"
        detailsHeightConstraint.constant = detailsVisible ? 130 : 0
        window.setContentSize(NSSize(width: window.frame.width, height: detailsVisible ? 560 : 410))
        refreshStatus()
    }

    @objc private func chooseWorkingDirectoryAction() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: workingDirectory)
        panel.prompt = "Use Folder"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        UserDefaults.standard.set(url.path, forKey: workingDirectoryDefaultsKey)
        updateWorkingDirectoryLabel()
        appendStatus("Working folder set to \(url.path). New sessions will start there.")
    }

    @objc private func toggleHideAfterAction() {
        UserDefaults.standard.set(hideAfterActionCheckbox.state == .on, forKey: hideAfterActionDefaultsKey)
    }

    private func openSession(_ target: Target) -> Bool {
        guard ensureTmux() else { return false }
        if hasSession(target.session) {
            appendStatus("\(target.label): already active. You can keep using Send Clipboard.")
            return true
        }

        guard let commandParts = detectCLI(target) else {
            appendStatus("\(target.label): command not found. Install or log in first.")
            showDetails()
            return false
        }

        let launchCommand = commandParts.map(shellQuote).joined(separator: " ")
        let createResult = runShell("tmux new-session -d -c \(shellQuote(workingDirectory)) -s \(shellQuote(target.session)) \(launchCommand)")
        if createResult.status != 0 {
            let output = createResult.output.trimmingCharacters(in: .whitespacesAndNewlines)
            appendStatus("\(target.label): could not start tmux session '\(target.session)'.\n\(output)")
            showDetails()
            return false
        }

        guard hasSession(target.session) else {
            appendStatus("\(target.label): start command finished, but no active tmux session was created.")
            showDetails()
            return false
        }

        let command = "tmux attach-session -t \(shellQuote(target.session))"
        let script = """
        tell application "Terminal"
          activate
          do script "\(escapeAppleScript(command))"
        end tell
        """
        if !runAppleScript(script) {
            appendStatus("\(target.label): session is active, but the Terminal attach window could not be opened.")
            showDetails()
        }
        appendStatus("Started \(target.label). Session '\(target.session)' is active.")
        return true
    }

    private func sendClipboard(to target: Target) -> Bool {
        guard ensureTmux() else { return false }
        guard hasSession(target.session) else {
            appendStatus("\(target.label): no tmux session named '\(target.session)'. Open it first.")
            showDetails()
            return false
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
            return true
        } else {
            appendStatus("\(target.label): send failed\n\(output)")
            showDetails()
            return false
        }
    }

    private func refreshStatus() {
        var lines: [String] = []
        lines.append("Status updated: \(DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium))")
        lines.append("")
        lines.append("tmux: \(runShell("command -v tmux").status == 0 ? "OK" : "missing")")
        lines.append("")

        let sessions = tmuxSessions()
        sessionCreatedTimes = tmuxSessionCreatedTimes()
        updateVisibleTargetState(activeSessions: sessions)
        for target in Target.all {
            let cli = detectCLI(target) == nil ? "missing" : "OK"
            let session = sessions.contains(target.session) ? "active" : "not running"
            lines.append("\(target.label): command \(cli), session '\(target.session)' \(session)")
        }

        if !sessions.isEmpty {
            lines.append("")
            lines.append("All tmux sessions: \(sessions.joined(separator: ", "))")
        }

        lines.append("")
        lines.append("Working folder: \(workingDirectory)")

        if !eventMessages.isEmpty {
            lines.append("")
            lines.append("Events:")
            lines.append(contentsOf: eventMessages.suffix(12))
        }

        setStatus(lines.joined(separator: "\n"))
    }

    private func updateVisibleTargetState(activeSessions: [String]) {
        for target in Target.all {
            let commandFound = detectCLI(target) != nil
            let active = activeSessions.contains(target.session)
            let suffix: String
            if active {
                suffix = " (active)"
            } else if commandFound {
                suffix = " (not running)"
            } else {
                suffix = " (missing)"
            }
            targetButtons[target.id]?.title = target.label + suffix
        }

        let selected = selectedTargets
        if selected.isEmpty {
            summaryLabel.stringValue = "Select one or more targets."
            summaryLabel.textColor = .secondaryLabelColor
            modeLabel.stringValue = "Ready"
            modeLabel.textColor = .labelColor
            durationLabel.stringValue = "Not running"
            durationLabel.textColor = .secondaryLabelColor
            modeDetailLabel.stringValue = "Select one or more targets to start protected sessions."
            openButton.title = "Start Selected"
            openButton.isEnabled = false
            sendSelectedButton.isEnabled = false
            stopSelectedButton.isEnabled = false
            return
        }

        let allSelectedActive = selected.allSatisfy { activeSessions.contains($0.session) }
        let anySelectedActive = selected.contains { activeSessions.contains($0.session) }
        if allSelectedActive {
            activeSince = selected
                .compactMap { sessionCreatedTimes[$0.session] }
                .min() ?? activeSince ?? Date()
            let elapsed = activeSince.map(formatElapsed) ?? "00:00"
            summaryLabel.stringValue = "Active for \(elapsed): clipboard sends to selected sessions."
            summaryLabel.textColor = .systemGreen
            modeLabel.stringValue = "Active"
            modeLabel.textColor = .systemGreen
            durationLabel.stringValue = elapsed
            durationLabel.textColor = .labelColor
            modeDetailLabel.stringValue = "Selected sessions are running. Send clipboard text or stop them."
            openButton.title = "Started"
            openButton.isEnabled = false
            sendSelectedButton.isEnabled = true
            stopSelectedButton.isEnabled = true
            scheduleActiveDurationRefresh()
        } else {
            activeSince = nil
            let missingCount = selected.filter { !activeSessions.contains($0.session) }.count
            summaryLabel.stringValue = "Needs start: \(missingCount) selected session\(missingCount == 1 ? "" : "s") not running."
            summaryLabel.textColor = .systemOrange
            modeLabel.stringValue = "Ready"
            modeLabel.textColor = .labelColor
            durationLabel.stringValue = "Not running"
            durationLabel.textColor = .secondaryLabelColor
            modeDetailLabel.stringValue = "Start selected targets to enter the active status screen."
            openButton.title = "Start Selected"
            openButton.isEnabled = true
            sendSelectedButton.isEnabled = false
            stopSelectedButton.isEnabled = anySelectedActive
        }
    }

    private func scheduleActiveDurationRefresh() {
        guard activeSince != nil, !activeRefreshScheduled else { return }
        activeRefreshScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            self.activeRefreshScheduled = false
            guard let activeSince = self.activeSince else { return }
            let elapsed = self.formatElapsed(from: activeSince)
            self.durationLabel.stringValue = elapsed
            self.summaryLabel.stringValue = "Active for \(elapsed): clipboard sends to selected sessions."
            self.scheduleActiveDurationRefresh()
        }
    }

    private func formatElapsed(from start: Date) -> String {
        let seconds = max(0, Int(Date().timeIntervalSince(start)))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
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
        window.setContentSize(NSSize(width: window.frame.width, height: 560))
    }

    private func returnFocusAfterSuccessfulAction() {
        guard hideAfterActionCheckbox.state == .on else {
            showWindow()
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self else { return }
            self.window.orderOut(nil)
            NSApp.hide(nil)
        }
    }

    private func updateWorkingDirectoryLabel() {
        guard let workingDirectoryLabel else { return }
        workingDirectoryLabel.stringValue = (workingDirectory as NSString).abbreviatingWithTildeInPath
    }

    private func isDirectory(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    private func detectCLI(_ target: Target) -> [String]? {
        if let cached = commandCache[target.id] {
            return cached
        }
        let command = firstExistingCommand(target.candidates)
        commandCache[target.id] = command
        return command
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

    private func tmuxSessionCreatedTimes() -> [String: Date] {
        let result = runShell("tmux list-sessions -F '#S|#{session_created}'")
        guard result.status == 0 else { return [:] }
        var values: [String: Date] = [:]
        for line in result.output.split(separator: "\n") {
            let parts = line.split(separator: "|", maxSplits: 1).map(String.init)
            guard parts.count == 2, let timestamp = TimeInterval(parts[1]) else { continue }
            values[parts[0]] = Date(timeIntervalSince1970: timestamp)
        }
        return values
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
        var outputData = Data()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            outputData = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            return ShellResult(status: process.terminationStatus, output: output)
        } catch {
            return ShellResult(status: 1, output: error.localizedDescription)
        }
    }

    private func appendStatus(_ message: String) {
        eventMessages.append(message)
        if eventMessages.count > 20 {
            eventMessages.removeFirst(eventMessages.count - 20)
        }
        refreshStatus()
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
