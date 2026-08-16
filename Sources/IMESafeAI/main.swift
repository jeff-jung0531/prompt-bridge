import AppKit
import Foundation
import QuartzCore

private let appName = "Long Paste Fix"
private let bundleVersion = "0.2.1"
private let fixedWindowContentSize = NSSize(width: 520, height: 214)
private let buttonHeight: CGFloat = 30
private let smallButtonHeight: CGFloat = 24
private let promptMaxFileCount = 20
private let promptMaxAge: TimeInterval = 7 * 24 * 60 * 60
private let layoutInset: CGFloat = 16
private let sectionToContentGap: CGFloat = 6
private let contentBlockGap: CGFloat = 12

private struct InputStats {
    let characters: Int
    let bytes: Int
    let lines: Int
}

private enum AppLanguage {
    case english
    case korean
    case japanese
    case chinese
}

private enum L10n {
    static let language: AppLanguage = {
        let localeLanguage = Locale.current.language
        let code = localeLanguage.languageCode?.identifier.lowercased() ?? "en"
        if code == "ko" { return .korean }
        if code == "ja" { return .japanese }
        if code == "zh" { return .chinese }
        return .english
    }()

    static func text(_ en: String, _ ko: String, _ ja: String, _ zh: String) -> String {
        switch language {
        case .english: return en
        case .korean: return ko
        case .japanese: return ja
        case .chinese: return zh
        }
    }
}

private enum GB {
    private static func hex(_ value: UInt32, _ alpha: CGFloat = 1) -> NSColor {
        NSColor(
            srgbRed: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: alpha
        )
    }

    static let ink = hex(0xF7FAFF)
    static let inkSoft = hex(0xE6EEF9)
    static let muted = hex(0xB9C3D1)
    static let faint = hex(0x7D8794)
    static let inkDisabled = hex(0xF7FAFF, 0.40)
    static let ice = hex(0xB9FFF2)
    static let led = hex(0x8CF7E1)
    static let ledTail = hex(0x3DC9B7)
    static let panelReadable = hex(0x22272D, 0.76)
    static let panelDark = hex(0x0D1218, 0.80)
    static let controlBg = NSColor(white: 1, alpha: 0.075)
    static let controlMuted = NSColor(white: 1, alpha: 0.045)
    static let controlActive = hex(0xB9FFF2, 0.18)
    static let controlDisabled = NSColor(white: 1, alpha: 0.04)
    static let hairline = NSColor(white: 1, alpha: 0.08)
    static let dotIdle = hex(0xF7FAFF, 0.28)
    static let radius: CGFloat = 8
    static let windowRadius: CGFloat = 12

    static let lineLight: [NSColor] = [
        NSColor(white: 1, alpha: 0.66),
        hex(0xDCEAF4, 0.34),
        NSColor(white: 1, alpha: 0.07),
        hex(0x081826, 0.22)
    ]
    static let lineLightStops: [NSNumber] = [0, 0.34, 0.58, 1]
    static let lineIce: [NSColor] = [
        NSColor(white: 1, alpha: 0.6),
        hex(0xB9FFF2, 0.76),
        hex(0x8CF7E1, 0.24),
        hex(0x3DC9B7, 0.28),
        hex(0x081826, 0.2)
    ]
    static let lineIceStops: [NSNumber] = [0, 0.42, 0.64, 0.78, 1]

    static func sans(_ size: CGFloat, _ weight: NSFont.Weight = .regular) -> NSFont {
        let name: String
        switch weight {
        case .bold: name = "Pretendard-Bold"
        case .semibold: name = "Pretendard-SemiBold"
        case .medium: name = "Pretendard-Medium"
        default: name = "Pretendard-Regular"
        }
        return NSFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight)
    }

    static func mono(_ size: CGFloat, _ weight: NSFont.Weight = .regular) -> NSFont {
        NSFont(name: "JetBrainsMono-Regular", size: size)
            ?? .monospacedSystemFont(ofSize: size, weight: weight)
    }
}

private final class GlassRingLayer: CAGradientLayer {
    private let ringMask = CAShapeLayer()
    private var radiusValue: CGFloat = GB.radius

    override init() {
        super.init()
        setup()
    }

    override init(layer: Any) {
        super.init(layer: layer)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        startPoint = CGPoint(x: 0, y: 1)
        endPoint = CGPoint(x: 1, y: 0)
        ringMask.fillColor = NSColor.clear.cgColor
        ringMask.strokeColor = NSColor.white.cgColor
        ringMask.lineWidth = 1
        mask = ringMask
        setActive(false)
    }

    func setActive(_ active: Bool) {
        colors = (active ? GB.lineIce : GB.lineLight).map(\.cgColor)
        locations = active ? GB.lineIceStops : GB.lineLightStops
    }

    func setCornerRadius(_ radius: CGFloat) {
        radiusValue = radius
        setNeedsLayout()
    }

    override func layoutSublayers() {
        super.layoutSublayers()
        ringMask.frame = bounds
        ringMask.path = CGPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
            cornerWidth: radiusValue,
            cornerHeight: radiusValue,
            transform: nil
        )
    }
}

private final class GlassPanelView: NSView {
    private let fillLayer = CALayer()
    private let ringLayer = GlassRingLayer()
    private let cornerRadiusValue: CGFloat
    private let cornerMask: CACornerMask

    init(
        dark: Bool = false,
        cornerRadius: CGFloat = GB.radius,
        maskedCorners: CACornerMask = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner,
            .layerMinXMaxYCorner,
            .layerMaxXMaxYCorner
        ]
    ) {
        cornerRadiusValue = cornerRadius
        cornerMask = maskedCorners
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = cornerRadius
        layer?.maskedCorners = maskedCorners
        layer?.masksToBounds = true
        layer?.cornerCurve = .continuous
        fillLayer.backgroundColor = (dark ? GB.panelDark : GB.panelReadable).cgColor
        fillLayer.cornerRadius = cornerRadius
        fillLayer.maskedCorners = maskedCorners
        fillLayer.cornerCurve = .continuous
        ringLayer.setCornerRadius(cornerRadius)
        ringLayer.maskedCorners = maskedCorners
        layer?.addSublayer(fillLayer)
        layer?.addSublayer(ringLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        fillLayer.frame = bounds
        ringLayer.frame = bounds
        layer?.cornerRadius = cornerRadiusValue
        layer?.maskedCorners = cornerMask
    }
}

private final class GlassButtonCell: NSButtonCell {
    var active = false
    var compact = false

    override func drawBezel(withFrame frame: NSRect, in controlView: NSView) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        defer { context.restoreGState() }

        let bounds = frame.insetBy(dx: 0.5, dy: 0.5)
        let path = NSBezierPath(roundedRect: bounds, xRadius: GB.radius, yRadius: GB.radius)
        let enabled = (controlView as? NSButton)?.isEnabled ?? true
        (enabled ? (active ? GB.controlActive : GB.controlBg) : GB.controlDisabled).setFill()
        path.fill()

        let border = NSBezierPath(roundedRect: bounds, xRadius: GB.radius, yRadius: GB.radius)
        (enabled ? (active ? GB.ice.withAlphaComponent(0.54) : NSColor.white.withAlphaComponent(0.28)) : NSColor.white.withAlphaComponent(0.15)).setStroke()
        border.lineWidth = 1
        border.stroke()

        if enabled {
            NSColor.white.withAlphaComponent(0.34).setStroke()
            let top = NSBezierPath()
            let topY = controlView.isFlipped ? bounds.minY + 1 : bounds.maxY - 1
            top.move(to: NSPoint(x: bounds.minX + GB.radius, y: topY))
            top.line(to: NSPoint(x: bounds.maxX - GB.radius, y: topY))
            top.lineWidth = 1
            top.stroke()
        }

        guard enabled && active else { return }
        let ledHeight: CGFloat = compact ? 1.5 : 2
        let ledY = controlView.isFlipped ? bounds.maxY - 2 - ledHeight : bounds.minY + 2
        let ledRect = NSRect(
            x: bounds.minX + 13,
            y: ledY,
            width: max(8, bounds.width - 26),
            height: ledHeight
        )
        let ledPath = NSBezierPath(roundedRect: ledRect, xRadius: ledHeight, yRadius: ledHeight)
        context.setShadow(offset: .zero, blur: compact ? 8 : 12, color: GB.led.withAlphaComponent(0.64).cgColor)
        NSGradient(colors: [
            GB.led.withAlphaComponent(0.00),
            GB.led.withAlphaComponent(0.96),
            GB.ice.withAlphaComponent(1.00),
            GB.ledTail.withAlphaComponent(0.88),
            GB.led.withAlphaComponent(0.00)
        ])?.draw(in: ledPath, angle: 0)
    }
}

private final class GlassButton: NSButton {
    private let dotLayer = CALayer()
    private var hasDot = false

    init(title: String, active: Bool = false, compact: Bool = false) {
        super.init(frame: .zero)
        setButtonType(.momentaryPushIn)
        isBordered = false
        bezelStyle = .rounded
        wantsLayer = true
        font = GB.sans(12, .semibold)
        contentTintColor = GB.inkSoft
        cell = GlassButtonCell()
        self.title = title
        (cell as? GlassButtonCell)?.active = active
        (cell as? GlassButtonCell)?.compact = compact
        dotLayer.cornerRadius = compact ? 2 : 2.5
        layer?.addSublayer(dotLayer)
        setDot(false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setActive(_ active: Bool) {
        (cell as? GlassButtonCell)?.active = active
        setDot(active)
        needsDisplay = true
    }

    func setCompact(_ compact: Bool) {
        font = GB.sans(compact ? 11 : 12, .semibold)
        (cell as? GlassButtonCell)?.compact = compact
        dotLayer.cornerRadius = compact ? 2 : 2.5
    }

    private func setDot(_ active: Bool) {
        hasDot = true
        dotLayer.backgroundColor = (active ? GB.led : GB.dotIdle).cgColor
        dotLayer.shadowColor = active ? GB.led.cgColor : nil
        dotLayer.shadowRadius = active ? 7 : 0
        dotLayer.shadowOpacity = active ? 0.7 : 0
        dotLayer.shadowOffset = .zero
    }

    override func layout() {
        super.layout()
        guard hasDot else { return }
        let size: CGFloat = (cell as? GlassButtonCell)?.compact == true ? 4 : 5
        dotLayer.frame = CGRect(x: 12, y: (bounds.height - size) / 2, width: size, height: size)
    }

    override var isEnabled: Bool {
        didSet {
            contentTintColor = isEnabled ? GB.inkSoft : GB.inkDisabled
            alphaValue = isEnabled ? 1 : 0.74
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private let promptStatusLabel = NSTextField(labelWithString: "")
    private let promptHintLabel = NSTextField(labelWithString: "")
    private let fileButton = GlassButton(title: "")
    private let copyButton = GlassButton(title: "")
    private let finderButton = GlassButton(title: "", compact: true)
    private let footerLabel = NSTextField(labelWithString: "")
    private let helpButton = NSButton(title: "i", target: nil, action: nil)
    private var lastPromptFileURL: URL?
    private var lastStats: InputStats?

    private var promptDirectory: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return base.appendingPathComponent("Long Paste Fix", isDirectory: true)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        buildWindow()
        refreshState()
        showWindow()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @objc private func showWindow() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func buildWindow() {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: fixedWindowContentSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = appName
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.minSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: fixedWindowContentSize)).size
        window.maxSize = window.minSize
        window.collectionBehavior = [.moveToActiveSpace]
        self.window = window

        let visual = NSVisualEffectView()
        visual.material = .hudWindow
        visual.blendingMode = .behindWindow
        visual.state = .active
        visual.translatesAutoresizingMaskIntoConstraints = false
        visual.wantsLayer = true
        visual.layer?.cornerRadius = GB.windowRadius
        visual.layer?.masksToBounds = true
        window.contentView = visual

        let root = NSView()
        root.translatesAutoresizingMaskIntoConstraints = false
        visual.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: visual.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: visual.trailingAnchor),
            root.topAnchor.constraint(equalTo: visual.topAnchor),
            root.bottomAnchor.constraint(equalTo: visual.bottomAnchor)
        ])

        let titlebar = makeTitlebar()
        let mainPanel = makeMainPanel()
        let footer = makeFooter()
        root.addSubview(titlebar)
        root.addSubview(mainPanel)
        root.addSubview(footer)
        NSLayoutConstraint.activate([
            titlebar.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            titlebar.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            titlebar.topAnchor.constraint(equalTo: root.topAnchor),
            titlebar.heightAnchor.constraint(equalToConstant: 38),
            mainPanel.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            mainPanel.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            mainPanel.topAnchor.constraint(equalTo: titlebar.bottomAnchor),
            mainPanel.bottomAnchor.constraint(equalTo: footer.topAnchor),
            footer.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            footer.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            footer.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            footer.heightAnchor.constraint(equalToConstant: 31)
        ])

        window.center()
    }

    private func makeTitlebar() -> NSView {
        let view = GlassPanelView(
            dark: true,
            cornerRadius: 0
        )
        view.translatesAutoresizingMaskIntoConstraints = false

        let title = NSTextField(labelWithString: appName)
        title.font = GB.sans(12, .bold)
        title.textColor = GB.ink
        title.alignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false

        helpButton.title = "i"
        helpButton.font = GB.sans(11, .medium)
        helpButton.contentTintColor = GB.faint
        helpButton.isBordered = false
        helpButton.target = self
        helpButton.action = #selector(showHelpAction)
        helpButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(title)
        view.addSubview(helpButton)
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 80),
            title.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -1),
            helpButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -layoutInset),
            helpButton.centerYAnchor.constraint(equalTo: title.centerYAnchor),
            helpButton.widthAnchor.constraint(equalToConstant: 20),
            helpButton.heightAnchor.constraint(equalToConstant: 20)
        ])
        return view
    }

    private func makeMainPanel() -> NSView {
        let panel = GlassPanelView(cornerRadius: 0)
        panel.translatesAutoresizingMaskIntoConstraints = false

        let copiedHeader = makeSectionHeader(
            L10n.text("COPIED TEXT", "복사된 텍스트", "コピーしたテキスト", "已复制文本")
        )

        let statusColumn = NSStackView()
        statusColumn.orientation = .vertical
        statusColumn.alignment = .leading
        statusColumn.spacing = 3
        statusColumn.translatesAutoresizingMaskIntoConstraints = false

        promptStatusLabel.font = GB.sans(12, .semibold)
        promptStatusLabel.textColor = GB.ink
        promptStatusLabel.alignment = .left
        promptStatusLabel.lineBreakMode = .byTruncatingTail
        promptHintLabel.font = GB.sans(12)
        promptHintLabel.textColor = GB.muted
        promptHintLabel.alignment = .left
        promptHintLabel.lineBreakMode = .byTruncatingTail
        statusColumn.addArrangedSubview(promptStatusLabel)
        statusColumn.addArrangedSubview(promptHintLabel)
        statusColumn.setContentHuggingPriority(.defaultLow, for: .horizontal)

        style(fileButton, title: L10n.text("Make File", "파일 만들기", "ファイル作成", "制作文件"), width: 112, height: buttonHeight)
        fileButton.target = self
        fileButton.action = #selector(makeFileAction)

        style(copyButton, title: L10n.text("Copy File", "파일 복사", "ファイルをコピー", "复制文件"), width: 112, height: buttonHeight)
        copyButton.target = self
        copyButton.action = #selector(copyFileAction)

        style(finderButton, title: L10n.text("Open Finder", "Finder 열기", "Finderで表示", "在Finder中显示"), width: 76, height: smallButtonHeight)
        finderButton.target = self
        finderButton.action = #selector(openFinderAction)

        statusColumn.widthAnchor.constraint(greaterThanOrEqualToConstant: 300).isActive = true

        let buttonRow = NSStackView(views: [fileButton, copyButton, NSView()])
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.distribution = .fill
        buttonRow.spacing = 8
        buttonRow.translatesAutoresizingMaskIntoConstraints = false

        let separator = makeSeparator()
        let browserHeader = makeSectionHeader(
            L10n.text("BROWSER ATTACHMENT", "브라우저 첨부", "ブラウザ添付", "浏览器附件")
        )

        [copiedHeader, statusColumn, finderButton, separator, browserHeader, buttonRow].forEach {
            panel.addSubview($0)
        }

        NSLayoutConstraint.activate([
            copiedHeader.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: layoutInset),
            copiedHeader.trailingAnchor.constraint(lessThanOrEqualTo: panel.trailingAnchor, constant: -layoutInset),
            copiedHeader.topAnchor.constraint(equalTo: panel.topAnchor, constant: 14),

            statusColumn.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: layoutInset),
            statusColumn.topAnchor.constraint(equalTo: copiedHeader.bottomAnchor, constant: sectionToContentGap),
            statusColumn.trailingAnchor.constraint(lessThanOrEqualTo: finderButton.leadingAnchor, constant: -12),

            finderButton.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -(layoutInset + 8)),
            finderButton.centerYAnchor.constraint(equalTo: statusColumn.centerYAnchor),

            separator.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: layoutInset),
            separator.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -layoutInset),
            separator.topAnchor.constraint(equalTo: statusColumn.bottomAnchor, constant: contentBlockGap),

            browserHeader.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: layoutInset),
            browserHeader.trailingAnchor.constraint(lessThanOrEqualTo: panel.trailingAnchor, constant: -layoutInset),
            browserHeader.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: contentBlockGap),

            buttonRow.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: layoutInset),
            buttonRow.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -layoutInset),
            buttonRow.topAnchor.constraint(equalTo: browserHeader.bottomAnchor, constant: sectionToContentGap)
        ])
        return panel
    }

    private func makeFooter() -> NSView {
        let footer = GlassPanelView(
            dark: true,
            cornerRadius: 0
        )
        footer.translatesAutoresizingMaskIntoConstraints = false

        footerLabel.font = GB.sans(11, .semibold)
        footerLabel.textColor = GB.inkSoft
        footerLabel.lineBreakMode = .byTruncatingTail
        footerLabel.translatesAutoresizingMaskIntoConstraints = false

        footer.addSubview(footerLabel)
        NSLayoutConstraint.activate([
            footerLabel.leadingAnchor.constraint(equalTo: footer.leadingAnchor, constant: layoutInset),
            footerLabel.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -layoutInset),
            footerLabel.centerYAnchor.constraint(equalTo: footer.centerYAnchor)
        ])
        return footer
    }

    private func makeSectionHeader(_ title: String) -> NSTextField {
        let label = NSTextField(labelWithString: title.uppercased())
        label.font = GB.sans(11, .semibold)
        label.textColor = GB.faint
        label.alignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func makeSeparator() -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = GB.hairline.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 1)
        ])
        return view
    }

    private func style(_ button: GlassButton, title: String, width: CGFloat, height: CGFloat) {
        button.title = title
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setCompact(height < buttonHeight)
        button.setActive(height >= buttonHeight)
        button.font = GB.sans(height < buttonHeight ? 11 : 12, .semibold)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: width),
            button.heightAnchor.constraint(equalToConstant: height)
        ])
    }

    private func refreshState() {
        if let fileURL = lastPromptFileURL {
            let statsText: String
            if let stats = lastStats {
                statsText = L10n.text(
                    "\(stats.characters) chars · \(stats.lines) lines",
                    "\(stats.characters)자 · \(stats.lines)줄",
                    "\(stats.characters)文字 · \(stats.lines)行",
                    "\(stats.characters)字 · \(stats.lines)行"
                )
            } else {
                statsText = fileURL.lastPathComponent
            }
            promptStatusLabel.stringValue = statsText
            promptHintLabel.stringValue = L10n.text(
                "Use Cmd+V in Claude. Copy File copies it again.",
                "Claude 입력창에서 Cmd+V를 누르세요. 파일 복사는 같은 파일을 다시 복사합니다.",
                "ClaudeでCmd+V。ファイルコピーで再コピーできます。",
                "在 Claude 中按 Cmd+V。复制文件可再次复制。"
            )
            footerLabel.stringValue = L10n.text(
                "File copied. Paste it into Claude.",
                "파일이 복사됐습니다. Claude에 붙여넣으세요.",
                "ファイルをコピーしました。Claudeに貼り付けてください。",
                "文件已复制。粘贴到 Claude。"
            )
            copyButton.isEnabled = true
            finderButton.isEnabled = true
        } else {
            promptStatusLabel.stringValue = L10n.text(
                "Copy long text",
                "긴 텍스트를 복사하세요",
                "長いテキストをコピー",
                "复制长文本"
            )
            promptHintLabel.stringValue = L10n.text(
                "Make File creates and copies an md file.",
                "파일 만들기는 md 파일을 만들고 바로 복사합니다.",
                "ファイル作成でmdファイルを作ってコピーします。",
                "制作文件会生成并复制 md 文件。"
            )
            footerLabel.stringValue = L10n.text(
                "Copy long text, then make a file.",
                "긴 텍스트를 복사한 뒤 파일을 만드세요.",
                "長いテキストをコピーしてからファイルを作成。",
                "复制长文本，然后制作文件。"
            )
            copyButton.isEnabled = false
            finderButton.isEnabled = false
        }
    }

    @objc private func makeFileAction() {
        guard let prompt = copiedPrompt() else {
            showAlert(
                title: L10n.text("No copied text", "복사된 텍스트 없음", "コピーしたテキストがありません", "没有复制的文本"),
                message: L10n.text(
                    "Copy long text first, then click Make File.",
                    "긴 텍스트를 먼저 복사한 뒤 파일 만들기를 누르세요.",
                    "先に長いテキストをコピーしてからファイル作成を押してください。",
                    "请先复制长文本，然后点击制作文件。"
                )
            )
            return
        }

        do {
            try FileManager.default.createDirectory(at: promptDirectory, withIntermediateDirectories: true)
            let fileURL = try writePromptFile(prompt)
            copyFileToPasteboard(fileURL)
            lastPromptFileURL = fileURL
            lastStats = stats(for: prompt)
            cleanupOldPromptFiles()
            refreshState()
        } catch {
            showAlert(
                title: L10n.text("Could not make file", "파일을 만들 수 없음", "ファイルを作成できません", "无法制作文件"),
                message: error.localizedDescription
            )
        }
    }

    @objc private func copyFileAction() {
        guard let fileURL = lastPromptFileURL else { return }
        copyFileToPasteboard(fileURL)
        refreshState()
    }

    @objc private func openFinderAction() {
        guard let fileURL = lastPromptFileURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }

    @objc private func showHelpAction() {
        showAlert(
            title: appName,
            message: L10n.text(
                "Turns copied long text into a real md file and copies that file. Use it when Claude turns a long paste into an attachment that arrives empty.\n\nFiles are kept in the app cache and can be opened from Finder.",
                "복사한 긴 텍스트를 실제 md 파일로 만들고 그 파일을 복사합니다. Claude에서 긴 붙여넣기가 빈 첨부로 들어갈 때 사용하세요.\n\n파일은 앱 캐시에 임시 저장되며 Finder에서 열 수 있습니다.",
                "コピーした長いテキストを実際のmdファイルにして、そのファイルをコピーします。Claudeで長い貼り付けが空の添付になる時に使います。\n\nファイルはアプリのキャッシュに保存され、Finderで開けます。",
                "把复制的长文本制作成真实 md 文件并复制该文件。Claude 将长粘贴变成空附件时使用。\n\n文件保存在应用缓存中，可在 Finder 中打开。"
            )
        )
    }

    private func copiedPrompt() -> String? {
        let text = NSPasteboard.general.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let text, !text.isEmpty else { return nil }
        return text
    }

    private func writePromptFile(_ prompt: String) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMdd-HHmm"
        let prefix = safeFilenamePrefix(prompt)
        var fileURL = promptDirectory.appendingPathComponent("\(prefix)-\(formatter.string(from: Date())).md")
        var suffix = 2
        while FileManager.default.fileExists(atPath: fileURL.path) {
            fileURL = promptDirectory.appendingPathComponent("\(prefix)-\(formatter.string(from: Date()))-\(suffix).md")
            suffix += 1
        }
        try prompt.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    private func copyFileToPasteboard(_ fileURL: URL) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([fileURL as NSURL])
    }

    private func stats(for text: String) -> InputStats {
        InputStats(
            characters: text.count,
            bytes: text.data(using: .utf8)?.count ?? 0,
            lines: max(1, text.components(separatedBy: .newlines).count)
        )
    }

    private func safeFilenamePrefix(_ text: String) -> String {
        let fallback = L10n.text("prompt", "프롬프트", "prompt", "prompt")
        let firstLine = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? fallback
        let cleaned = firstLine
            .precomposedStringWithCanonicalMapping
            .replacingOccurrences(of: #"[/:\\?%*|"<>]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let prefix = cleaned.isEmpty ? fallback : cleaned
        return String(prefix.prefix(36))
    }

    private func cleanupOldPromptFiles() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: promptDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        let now = Date()
        let dated = files.compactMap { url -> (URL, Date)? in
            guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey]) else { return nil }
            return (url, values.contentModificationDate ?? .distantPast)
        }.sorted { $0.1 > $1.1 }

        for (index, item) in dated.enumerated() {
            if index >= promptMaxFileCount || now.timeIntervalSince(item.1) > promptMaxAge {
                try? FileManager.default.removeItem(at: item.0)
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: window)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
