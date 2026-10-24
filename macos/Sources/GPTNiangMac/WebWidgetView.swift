import SwiftUI
import AppKit
import WebKit
import GPTNiangCore

/// WebKit owns drawing only. Native code owns quota, images, input and windows.
@MainActor struct WidgetView: NSViewRepresentable {
    @ObservedObject var model: WidgetModel
    let onDrag: (CGSize) -> Void
    let onSettings: () -> Void
    let onContextMenu: (NSEvent, NSView) -> Void
    func makeCoordinator() -> WidgetWebCoordinator { WidgetWebCoordinator(model: model) }
    func makeNSView(context: Context) -> WidgetWebContainer {
        let view = context.coordinator.makeView()
        updateNSView(view, context: context)
        return view
    }
    func updateNSView(_ view: WidgetWebContainer, context: Context) {
        context.coordinator.onSettings = onSettings
        view.pointer.onPress = { [weak view] down in
            model.interactionActive = down; model.play(down ? "press" : "release")
            view?.browser.callAsyncJavaScript("window.GPTNiang?.press(down)", arguments: ["down": down], in: nil, in: .page, completionHandler: nil)
        }
        view.pointer.onDrag = { delta in onDrag(delta); if delta == .zero { model.savePreferences() } }
        view.pointer.onClick = { model.characterClick() }
        view.pointer.onMenu = onContextMenu
        view.pointer.onHover = { [weak view] in view?.setHover($0) }
        context.coordinator.update()
    }
    static func dismantleNSView(_ view: WidgetWebContainer, coordinator: WidgetWebCoordinator) { coordinator.stop() }
}

private func webValue<T>(_ value: T?) -> Any {
    if let value { return value }; return NSNull()
}

enum WidgetWebPolicy {
    static let entry = URL(string: "gpt-niang://widget/index.html")!
    static let actions: Set<String> = ["ready", "character", "bubble", "refresh", "settings"]
    static func isEntry(_ url: URL?) -> Bool { url == entry }
    static func action(_ body: Any) -> String? {
        guard let row = body as? [String: Any], row.count == 1,
              let action = row["action"] as? String, actions.contains(action) else { return nil }
        return action
    }
}

final class WidgetAssetHandler: NSObject, WKURLSchemeHandler {
    let root: URL
    var normal: URL
    var low: URL
    init(root: URL, normal: URL, low: URL) { self.root = root; self.normal = normal; self.low = low }
    func resource(_ url: URL) -> (URL, String)? {
        guard url.scheme == "gpt-niang", url.host == "widget", url.user == nil, url.password == nil,
              url.port == nil, url.fragment == nil else { return nil }
        if ["/normal.png", "/low.png", "/egg-squish.png", "/egg-dance.gif"].contains(url.path) {
            if let query = url.query, query.range(of: #"^revision=[0-9]+$"#, options: .regularExpression) == nil { return nil }
            if url.path == "/normal.png" { return (normal, "image/png") }
            if url.path == "/low.png" { return (low, "image/png") }
            return (root.appendingPathComponent(String(url.path.dropFirst())), url.path.hasSuffix(".gif") ? "image/gif" : "image/png")
        }
        guard url.query == nil else { return nil }
        let files = ["/index.html": "text/html", "/widget.css": "text/css", "/widget.js": "text/javascript"]
        guard let type = files[url.path] else { return nil }
        return (root.appendingPathComponent(String(url.path.dropFirst())), type)
    }
    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard (task.request.httpMethod ?? "GET") == "GET", let url = task.request.url,
              let (file, type) = resource(url), let data = try? Data(contentsOf: file) else {
            task.didFailWithError(URLError(.fileDoesNotExist)); return
        }
        task.didReceive(URLResponse(url: url, mimeType: type, expectedContentLength: data.count, textEncodingName: "utf-8"))
        task.didReceive(data); task.didFinish()
    }
    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}

@MainActor final class WidgetWebCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    let model: WidgetModel
    weak var view: WidgetWebContainer?
    var onSettings: () -> Void = {}
    private var assets: WidgetAssetHandler?
    private var ready = false
    private var lastPayload: Data?
    private var imageRevision = -1
    init(model: WidgetModel) { self.model = model }
    func makeView() -> WidgetWebContainer {
        let root = Bundle.module.resourceURL!.appendingPathComponent("WebWidget", isDirectory: true)
        let handler = WidgetAssetHandler(root: root, normal: model.characterImages.url(.normal), low: model.characterImages.url(.low))
        assets = handler
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        config.mediaTypesRequiringUserActionForPlayback = .all
        config.setURLSchemeHandler(handler, forURLScheme: "gpt-niang")
        config.userContentController.add(self, name: "widget")
        let browser = WKWebView(frame: .zero, configuration: config)
        browser.setValue(false, forKey: "drawsBackground")
        browser.underPageBackgroundColor = .clear
        browser.navigationDelegate = self
        let result = WidgetWebContainer(browser: browser)
        view = result; browser.load(URLRequest(url: WidgetWebPolicy.entry))
        return result
    }
    func stop() {
        model.webViewReady = false
        view?.browser.configuration.userContentController.removeScriptMessageHandler(forName: "widget")
        view?.browser.navigationDelegate = nil; view?.browser.stopLoading()
        view?.window.map { ($0 as? WidgetPanel)?.interactiveAtScreenPoint = nil }
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(WidgetWebPolicy.isEntry(navigationAction.request.url) && navigationAction.targetFrame?.isMainFrame == true ? .allow : .cancel)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard WidgetWebPolicy.isEntry(webView.url) else { return }
        ready = true; lastPayload = nil; update()
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        // Reload bundled content after WebKit memory pressure, never a remote URL.
        model.webViewReady = false
        ready = false; lastPayload = nil; webView.load(URLRequest(url: WidgetWebPolicy.entry))
    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.webView === view?.browser, message.frameInfo.isMainFrame,
              WidgetWebPolicy.isEntry(message.frameInfo.request.url), let action = WidgetWebPolicy.action(message.body) else { return }
        switch action {
        case "ready": model.webViewReady = true; ready = true; lastPayload = nil; update()
        case "character": model.characterClick()
        case "bubble": model.clickBubble()
        case "refresh": model.refresh(renewBubble: true)
        case "settings": onSettings()
        default: break
        }
    }
    func update() {
        guard let view else { return }
        assets?.normal = model.characterImages.url(.normal); assets?.low = model.characterImages.url(.low)
        if imageRevision != model.characterRevision || view.low != model.isLowQuota || view.egg != model.easterEgg {
            imageRevision = model.characterRevision
            view.mask = CharacterHitMask(image: model.easterEgg.flatMap { model.easterEggImage($0) } ?? model.characterImages.image(model.isLowQuota ? .low : .normal))
        }
        view.configure(scale: model.displayScale, mirrored: model.facingLeft, bubble: model.bubble,
                       low: model.isLowQuota, hideMenu: model.hideMenu, egg: model.easterEgg)
        guard ready else { return }
        let now = Date()
        let rows: [[String: Any]] = model.snapshot.displayWindows.map { window in
            ["title": window.title(language: model.language), "remaining": window.remaining,
             "resetsAt": webValue(window.resetsAt.map { $0 * 1000 }),
             "resetText": window.resetText(at: now, countdown: false, language: model.language)]
        }
        let payload: [String: Any] = [
            "bubble": model.bubble, "message": webValue(model.message),
            "completion": model.isCompletionMessage, "low": model.isLowQuota,
            "mirrored": model.facingLeft, "scale": model.displayScale, "hideMenu": model.hideMenu,
            "revision": model.characterRevision, "refreshing": model.refreshing,
            "egg": webValue(model.easterEgg?.rawValue), "eggGeneration": model.easterEggGeneration,
            "eggLoops": model.easterEgg.map { model.loopCount($0) } ?? 1,
            "characterBaseline": view.characterBaseline,
            "colorScope": model.colorScope.rawValue, "colorPaused": model.colorPaused,
            "palette": Appearance.palette(for: model.message ?? "", rainbow: model.colorMode == .rainbow || model.message == nil),
            "stale": model.snapshot.stale(at: now), "ok": model.snapshot.ok,
            "observedAt": webValue(model.snapshot.observedAt),
            "title": model.text(model.snapshot.ok ? "剩餘額度" : "暂无法读取"),
            "plan": model.snapshot.planLabel ?? model.text("未知套餐"),
            "error": model.snapshot.error ?? model.text("目前帳戶未提供額度視窗"), "windows": rows,
            "labels": ["refresh": model.text("刷新額度"), "settings": model.text("掛件設定"),
                "character": model.text("GPT 娘：點擊查看額度，拖動調整位置"),
                "stale": model.text("舊快照 · 刷新後確認"), "wait": model.text("等待更新後的額度"),
                "minutes": model.text("%@ 分鐘後重置"), "hours": model.text("%@ 小時 %@ 分鐘後重置"),
                "reset": model.text("%@ 重置")]
        ]
        guard let encoded = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
              encoded != lastPayload else { return }
        lastPayload = encoded
        view.browser.callAsyncJavaScript("window.GPTNiang.render(state)", arguments: ["state": payload], in: nil, in: .page, completionHandler: nil)
    }
}

@MainActor final class WidgetWebContainer: NSView {
    let browser: WKWebView
    let pointer = CharacterInteraction.PointerView()
    var mask = CharacterHitMask(image: nil)
    private(set) var low = false
    private(set) var egg: EasterEgg?
    private var scale: CGFloat = 1
    private var mirrored = false
    private var bubble = false
    private var hideMenu = false
    private var hovered = false
    private var geometryGeneration = 0
    override var isFlipped: Bool { true }
    init(browser: WKWebView) {
        self.browser = browser
        super.init(frame: CGRect(x: 0, y: 0, width: 378, height: 378))
        addSubview(browser); addSubview(pointer)
        wantsLayer = true; layer?.backgroundColor = NSColor.clear.cgColor
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
    override func layout() { super.layout(); browser.frame = bounds; positionPointer() }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let panel = window as? WidgetPanel {
            panel.interactiveAtScreenPoint = { [weak self] screen in
                guard let self, let window = self.window else { return false }
                return self.interactive(self.convert(window.convertPoint(fromScreen: screen), from: nil))
            }
            updateVisibleBounds()
        }
    }
    func configure(scale: Double, mirrored: Bool, bubble: Bool, low: Bool, hideMenu: Bool, egg: EasterEgg? = nil) {
        let closing = self.bubble && !bubble
        self.scale = max(0.1, scale); self.mirrored = mirrored; self.bubble = bubble
        self.low = low; self.hideMenu = hideMenu; self.egg = egg; positionPointer()
        geometryGeneration += 1
        let token = geometryGeneration
        if !closing { updateVisibleBounds() }
        else {
            // Keep the outgoing bubble in the native viewport until it fades.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) { [weak self] in
                guard let self, self.geometryGeneration == token else { return }; self.updateVisibleBounds()
            }
        }
    }
    func setHover(_ value: Bool) {
        guard hovered != value else { return }; hovered = value
        browser.callAsyncJavaScript("window.GPTNiang?.hover(value)", arguments: ["value": value], in: nil, in: .page, completionHandler: nil)
        updateVisibleBounds()
    }
    private var characterBox: CGRect { CGRect(x: 14 + (mirrored ? 0 : 142), y: 156, width: 208, height: 208) }
    var characterBaseline: Double {
        let fit = mask.fitted(in: characterBox)
        return min(1, max(0, (fit.minY + mask.normalizedBounds.maxY * fit.height - characterBox.minY) / characterBox.height))
    }
    private var settingsBox: CGRect { CGRect(x: 14 + (mirrored ? 6 : 320), y: 176, width: 24, height: 24) }
    private func positionPointer() {
        pointer.frame = characterBox.applying(CGAffineTransform(scaleX: scale, y: scale))
        pointer.toolTip = "点击查看额度，拖动调整位置"
    }
    private func logical(_ point: CGPoint) -> CGPoint { CGPoint(x: point.x/scale, y: point.y/scale) }
    private func characterHit(_ p: CGPoint) -> Bool {
        let fit = mask.fitted(in: characterBox)
        guard fit.contains(p), fit.width > 0, fit.height > 0 else { return false }
        let x = (p.x-fit.minX)/fit.width, y = (p.y-fit.minY)/fit.height
        return mask.contains(CGPoint(x: mirrored ? 1-x : x, y: y))
    }
    func interactive(_ point: CGPoint) -> Bool {
        let p = logical(point)
        if !hideMenu && hovered && settingsBox.contains(p) { return true }
        if characterHit(p) { return true }
        guard bubble && egg == nil else { return false }
        let x = mirrored ? 350-(p.x-14) : p.x-14, y = p.y-14
        func ellipse(_ r: CGRect) -> Bool {
            let dx = (x-r.midX)/(r.width/2), dy = (y-r.midY)/(r.height/2)
            return dx*dx+dy*dy <= 1
        }
        return ellipse(CGRect(x: 27, y: 6, width: 256, height: 158)) ||
            ellipse(CGRect(x: 108, y: 182, width: 25, height: 18)) ||
            ellipse(CGRect(x: 142, y: 214, width: 17, height: 12)) ||
            CGRect(x: 114, y: 150, width: 35, height: 20).contains(CGPoint(x: x, y: y))
    }
    override func hitTest(_ point: NSPoint) -> NSView? {
        let p = convert(point, from: superview)
        guard interactive(p) else { return nil }
        let q = logical(p)
        if !hideMenu && hovered && settingsBox.contains(q) { return browser.hitTest(convert(p, to: browser.superview)) }
        if characterHit(q) { return pointer }
        return super.hitTest(point)
    }
    private func updateVisibleBounds() {
        guard let panel = window as? WidgetPanel else { return }
        let fit = mask.fitted(in: characterBox), n = mask.normalizedBounds
        panel.characterBottom = max(0, (378 - fit.minY - n.maxY * fit.height) * scale)
        var rect = CGRect(x: fit.minX+(mirrored ? 1-n.maxX : n.minX)*fit.width, y: fit.minY+n.minY*fit.height,
                          width: n.width*fit.width, height: n.height*fit.height).insetBy(dx: -2, dy: -2)
        if egg != nil { rect = rect.union(characterBox.insetBy(dx: -24, dy: -36)) }
        if !hideMenu && hovered { rect = rect.union(settingsBox) }
        if bubble && egg == nil {
            let cloud = CGRect(x: 14+(mirrored ? 67 : 27), y: 20, width: 256, height: 224)
            rect = rect.union(cloud.insetBy(dx: -4, dy: -4))
        }
        panel.setVisibleContent(CGRect(x: rect.minX*scale, y: (378-rect.maxY)*scale,
                                      width: rect.width*scale, height: rect.height*scale))
    }
}
