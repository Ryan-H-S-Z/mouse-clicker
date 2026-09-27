import AppKit
import SwiftUI
import ApplicationServices
import Carbon

private let toggleNotification = Notification.Name("ClickerToggle")

final class Clicker: ObservableObject {
    enum Phase { case idle, countdown, running }
    @Published var interval = "100"
    @Published var limit = "100"
    @Published var unlimited = true
    @Published var rightButton = false
    @Published var phase: Phase = .idle
    @Published var remaining = 3
    @Published var count = 0
    @Published var trusted = AXIsProcessTrusted()
    @Published var message = "设置完成后开始，将鼠标移到需要点击的位置。"
    @Published var shortcutAvailable = false
    private var timer: Timer?
    private var permissionTimer: Timer?
    private var targetCount: Int?
    private var seconds = 0.1
    var active: Bool { phase != .idle }

    init() {
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.trusted = AXIsProcessTrusted()
            if self.active && !self.trusted { self.stop("权限已撤销，连点已停止。") }
        }
    }

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }

    func toggle() { active ? stop() : start() }

    func start() {
        guard !active else { return }
        trusted = AXIsProcessTrusted()
        guard trusted else { message = "请先在系统设置中允许本应用使用辅助功能。"; return }
        guard let ms = Double(interval.trimmingCharacters(in: .whitespacesAndNewlines)),
              ms.isFinite, ms >= 20, ms <= 3_600_000 else {
            message = "点击间隔请输入 20 至 3,600,000 毫秒。"; return
        }
        if unlimited { targetCount = nil }
        else {
            guard let n = Int(limit.trimmingCharacters(in: .whitespacesAndNewlines)), n > 0, n <= 10_000_000 else {
                message = "点击次数请输入 1 至 10,000,000 的整数。"; return
            }
            targetCount = n
        }
        guard shortcutAvailable else { message = "全局快捷键注册失败，请退出占用 ⌃⌥空格 的应用后重启。"; return }
        seconds = ms / 1000
        count = 0
        remaining = 3
        phase = .countdown
        message = "请将鼠标移到目标位置；按 Esc 可以取消。"
        let countdown = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.remaining -= 1
            if self.remaining == 0 { self.beginClicking() }
        }
        timer = countdown
        RunLoop.main.add(countdown, forMode: .common)
    }

    private func beginClicking() {
        timer?.invalidate()
        phase = .running
        message = "跟随鼠标当前位置点击。按 ⌃⌥空格 或 Esc 停止。"
        let repeating = Timer(timeInterval: seconds, repeats: true) { [weak self] _ in self?.click() }
        timer = repeating
        RunLoop.main.add(repeating, forMode: .common)
        click()
    }

    private func click() {
        guard phase == .running else { return }
        guard AXIsProcessTrusted() else { stop("缺少辅助功能权限，已停止。"); return }
        guard let position = CGEvent(source: nil)?.location,
              let source = CGEventSource(stateID: .hidSystemState) else { stop("无法读取鼠标位置，已停止。"); return }
        // Quartz coordinates and event coordinates share the same origin, including on multiple displays.
        let button: CGMouseButton = rightButton ? .right : .left
        guard let down = CGEvent(mouseEventSource: source, mouseType: rightButton ? .rightMouseDown : .leftMouseDown,
                                 mouseCursorPosition: position, mouseButton: button),
              let up = CGEvent(mouseEventSource: source, mouseType: rightButton ? .rightMouseUp : .leftMouseUp,
                               mouseCursorPosition: position, mouseButton: button) else {
            stop("无法创建鼠标事件，已停止。"); return
        }
        down.setIntegerValueField(.mouseEventClickState, value: 1)
        up.setIntegerValueField(.mouseEventClickState, value: 1)
        down.flags = []
        up.flags = []
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        count += 1
        if let target = targetCount, count >= target { stop("已完成 \(count) 次点击。") }
    }

    func stop(_ reason: String = "已停止。") {
        timer?.invalidate()
        timer = nil
        phase = .idle
        message = reason
    }
}

struct ContentView: View {
    @ObservedObject var model: Clicker
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 14) {
                Image(systemName: "computermouse.fill")
                    .font(.system(size: 32)).foregroundStyle(.blue)
                    .frame(width: 62, height: 62).background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 4) {
                    Text("鼠标连点器").font(.system(size: 24, weight: .bold))
                    Text("轻量、可控，跟随鼠标位置点击").foregroundStyle(.secondary)
                }
                Spacer()
            }
            HStack {
                Image(systemName: model.trusted ? "checkmark.circle.fill" : "lock.fill")
                    .foregroundStyle(model.trusted ? Color.green : Color.orange)
                Text(model.trusted ? "辅助功能权限已开启" : "需要辅助功能权限")
                Spacer()
                if !model.trusted { Button("前往授权") { model.requestPermission() } }
            }.padding(12).background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("点击按键").frame(width: 80, alignment: .leading)
                    Picker("点击按键", selection: $model.rightButton) {
                        Text("鼠标左键").tag(false)
                        Text("鼠标右键").tag(true)
                    }.pickerStyle(.segmented).labelsHidden()
                }
                HStack {
                    Text("点击间隔").frame(width: 80, alignment: .leading)
                    TextField("100", text: $model.interval).textFieldStyle(.roundedBorder).frame(width: 110)
                    Text("毫秒").foregroundStyle(.secondary)
                    Spacer()
                    Menu("常用间隔") {
                        ForEach([20, 50, 100, 500, 1000], id: \.self) { value in
                            Button("\(value) 毫秒") { model.interval = String(value) }
                        }
                    }.fixedSize()
                }
                HStack {
                    Text("点击次数").frame(width: 80, alignment: .leading)
                    Toggle("无限", isOn: $model.unlimited).toggleStyle(.checkbox)
                    if !model.unlimited {
                        TextField("100", text: $model.limit).textFieldStyle(.roundedBorder).frame(width: 110)
                        Text("次").foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }.disabled(model.active)

            Divider()
            HStack(alignment: .firstTextBaseline) {
                Text(model.phase == .countdown ? "\(model.remaining) 秒后开始" : model.phase == .running ? "正在连点" : "准备就绪")
                    .font(.headline).foregroundStyle(model.active ? Color.blue : Color.primary)
                Spacer()
                Text("\(model.count)").font(.system(size: 30, weight: .semibold, design: .rounded)).monospacedDigit()
                Text("次点击").foregroundStyle(.secondary)
            }
            Text(model.message).font(.callout).foregroundStyle(.secondary).frame(minHeight: 36, alignment: .topLeading)
            Button(action: model.toggle) {
                Label(model.active ? "停止连点" : "开始连点", systemImage: model.active ? "stop.fill" : "play.fill")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 9)
            }.buttonStyle(.borderedProminent).tint(model.active ? .red : .blue)
                .disabled(!model.trusted || !model.shortcutAvailable)
            Text(model.shortcutAvailable ? "⌃⌥ 空格  开始 / 停止    ·    Esc  紧急停止" : "全局快捷键不可用，请检查快捷键冲突并重启应用。")
                .font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
        }.padding(28).frame(width: 480)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let model = Clicker()
    var window: NSWindow!
    var statusItem: NSStatusItem!
    var hotKey: EventHotKeyRef?
    var eventHandler: EventHandlerRef?
    var globalMonitor: Any?
    var localMonitor: Any?
    var toggleObserver: NSObjectProtocol?
    var sleepObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        let quitItem = NSMenuItem(title: "退出鼠标连点器", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        appMenu.addItem(quitItem)
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        let editItem = NSMenuItem(title: "编辑", action: nil, keyEquivalent: "")
        let editMenu = NSMenu(title: "编辑")
        for (title, action, key) in [("剪切", "cut:", "x"), ("复制", "copy:", "c"),
                                     ("粘贴", "paste:", "v"), ("全选", "selectAll:", "a")] {
            editMenu.addItem(NSMenuItem(title: title, action: Selector(action), keyEquivalent: key))
        }
        editItem.submenu = editMenu
        mainMenu.addItem(editItem)
        NSApp.mainMenu = mainMenu
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 530),
                          styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "鼠标连点器"
        window.contentView = NSHostingView(rootView: ContentView(model: model))
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "computermouse", accessibilityDescription: "鼠标连点器")
        let menu = NSMenu()
        for (title, action) in [("显示连点器", #selector(showWindow)), ("开始 / 停止  ⌃⌥空格", #selector(toggle)),
                                ("停止", #selector(stop)), ("退出", #selector(quit))] {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }
        statusItem.menu = menu

        var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let handlerStatus = InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var identifier = EventHotKeyID()
            guard let event = event,
                  GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                                    nil, MemoryLayout<EventHotKeyID>.size, nil, &identifier) == noErr,
                  identifier.signature == 0x434C494B, identifier.id == 1 else { return OSStatus(eventNotHandledErr) }
            NotificationCenter.default.post(name: toggleNotification, object: nil)
            return noErr
        }, 1, &type, nil, &eventHandler)
        let keyStatus = RegisterEventHotKey(UInt32(kVK_Space), UInt32(controlKey | optionKey),
                                           EventHotKeyID(signature: 0x434C494B, id: 1), GetApplicationEventTarget(), 0, &hotKey)
        model.shortcutAvailable = handlerStatus == noErr && keyStatus == noErr
        toggleObserver = NotificationCenter.default.addObserver(forName: toggleNotification, object: nil, queue: .main) { [weak self] _ in self?.model.toggle() }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { self?.model.stop() }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { self?.model.stop() }
            return event
        }
        sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.willSleepNotification,
                                                                          object: nil, queue: .main) { [weak self] _ in
            self?.model.stop("电脑进入睡眠，已停止。")
        }
    }

    @objc func showWindow() { window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
    @objc func toggle() { model.toggle() }
    @objc func stop() { model.stop() }
    @objc func quit() { model.stop(); NSApp.terminate(nil) }
    func windowWillClose(_ notification: Notification) { model.stop() }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { showWindow(); return true }
    func applicationWillTerminate(_ notification: Notification) {
        model.stop()
        if let hotKey = hotKey { UnregisterEventHotKey(hotKey) }
        if let eventHandler = eventHandler { RemoveEventHandler(eventHandler) }
        if let monitor = globalMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = localMonitor { NSEvent.removeMonitor(monitor) }
        if let observer = toggleObserver { NotificationCenter.default.removeObserver(observer) }
        if let observer = sleepObserver { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
