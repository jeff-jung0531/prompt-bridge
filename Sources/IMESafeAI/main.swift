import AppKit
import Foundation

enum Target: String {
    case claude
    case codex
    case gemini

    var label: String {
        switch self {
        case .claude: return "Claude Code"
        case .codex: return "Codex"
        case .gemini: return "Gemini CLI"
        }
    }

    var session: String { rawValue }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var target: Target = .claude
    private let appName = "IME Safe AI CLI Terminal"
    private let pathValue = "\(NSHomeDirectory())/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Applications/ChatGPT.app/Contents/Resources"

    private var resourceURL: URL {
        Bundle.main.resourceURL ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        showMainMenu()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NSApp.activate(ignoringOtherApps: true)
        showMainMenu()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func showMainMenu() {
        let alert = NSAlert()
        alert.messageText = appName
        alert.informativeText = "Target: \(target.label)\n\nChoose what to do next."
        alert.addButton(withTitle: "Open AI CLI")
        alert.addButton(withTitle: "Send Clipboard")
        alert.addButton(withTitle: "GitHub")
        alert.addButton(withTitle: "Quit")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            chooseTargetThenOpen()
        case .alertSecondButtonReturn:
            sendClipboard()
        case .alertThirdButtonReturn:
            openGitHub()
        default:
            NSApp.terminate(nil)
        }
    }

    private func chooseTargetThenOpen() {
        let alert = NSAlert()
        alert.messageText = "Choose AI CLI"
        alert.informativeText = "Select the AI CLI session to open."
        alert.addButton(withTitle: "Claude Code")
        alert.addButton(withTitle: "Codex")
        alert.addButton(withTitle: "Gemini CLI")
        alert.addButton(withTitle: "Cancel")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            target = .claude
        case .alertSecondButtonReturn:
            target = .codex
        case .alertThirdButtonReturn:
            target = .gemini
        default:
            showMainMenu()
            return
        }

        openSession()
        showMainMenu()
    }

    private func openSession() {
        guard ensureTmux() else { return }
        guard let cli = detectCLI(target) else {
            showInfo("\(target.label) was not found on this Mac. Install or log in to it first.")
            return
        }

        let command = "tmux new-session -A -s \(shellQuote(target.session)) \(shellQuote(cli))"
        let script = """
        tell application "Terminal"
          activate
          do script "\(escapeAppleScript(command))"
        end tell
        """
        _ = runAppleScript(script)
        showInfo("Opened \(target.label) in a tmux session named '\(target.session)'. Keep that Terminal window open.")
    }

    private func sendClipboard() {
        guard ensureTmux() else { return }
        guard runShell("tmux has-session -t \(shellQuote(target.session))").status == 0 else {
            showInfo("No '\(target.session)' session is running yet. Open the AI CLI session first.")
            return
        }

        let alert = NSAlert()
        alert.messageText = "Send Clipboard"
        alert.informativeText = "Send the current clipboard to '\(target.session)'?"
        alert.addButton(withTitle: "Paste and Enter")
        alert.addButton(withTitle: "Paste only")
        alert.addButton(withTitle: "Cancel")

        let pasteScript = resourceURL.appendingPathComponent("ai-cli-paste").path
        let result: ShellResult
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            result = runExecutable(pasteScript, args: [target.session, "--enter"])
        case .alertSecondButtonReturn:
            result = runExecutable(pasteScript, args: [target.session])
        default:
            showMainMenu()
            return
        }

        showInfo(result.output.isEmpty ? "Done." : result.output)
        showMainMenu()
    }

    private func ensureTmux() -> Bool {
        if runShell("command -v tmux").status == 0 {
            return true
        }

        if runShell("command -v brew").status != 0 {
            showInfo("tmux is required, but Homebrew was not found. Install Homebrew first, then run: brew install tmux")
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
        showInfo("A Terminal window is installing tmux. Open this app again after installation finishes.")
        return false
    }

    private func detectCLI(_ target: Target) -> String? {
        switch target {
        case .claude:
            return firstExistingCommand(["claude", "\(NSHomeDirectory())/.local/bin/claude"])
        case .codex:
            return firstExistingCommand(["codex", "/Applications/ChatGPT.app/Contents/Resources/codex"])
        case .gemini:
            return firstExistingCommand(["gemini", "\(NSHomeDirectory())/.local/bin/gemini"])
        }
    }

    private func firstExistingCommand(_ candidates: [String]) -> String? {
        for candidate in candidates {
            if candidate.contains("/") {
                if FileManager.default.isExecutableFile(atPath: candidate) {
                    return candidate
                }
            } else {
                let result = runShell("command -v \(shellQuote(candidate))")
                if result.status == 0 {
                    let value = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !value.isEmpty { return value }
                }
            }
        }
        return nil
    }

    private func openGitHub() {
        NSWorkspace.shared.open(URL(string: "https://github.com/jeff-jung0531/ime-safe-ai-cli-terminal")!)
        showMainMenu()
    }

    private func showInfo(_ message: String) {
        let alert = NSAlert()
        alert.messageText = appName
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func runAppleScript(_ source: String) -> Bool {
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error {
            showInfo("AppleScript error: \(error)")
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

    private func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private func escapeAppleScript(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

struct ShellResult {
    let status: Int32
    let output: String
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
