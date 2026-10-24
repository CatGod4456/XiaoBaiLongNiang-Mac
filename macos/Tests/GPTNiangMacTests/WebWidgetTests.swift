import XCTest
import AppKit
import GPTNiangCore
@testable import GPTNiangMac

final class WebWidgetTests: XCTestCase {
    func testPackagedWebResourcesArePreferredOverTheBuildTree() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let app = root.appendingPathComponent("Fixture.app"), contents = app.appendingPathComponent("Contents")
        let resources = contents.appendingPathComponent("Resources")
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
        let metadata = ["CFBundleIdentifier": "test.gpt-niang.packaged-resources", "CFBundlePackageType": "APPL"]
        try PropertyListSerialization.data(fromPropertyList: metadata, format: .xml, options: 0)
            .write(to: contents.appendingPathComponent("Info.plist"))
        let packaged = resources.appendingPathComponent("GPTNiangMac_GPTNiangMac.bundle")
        try FileManager.default.copyItem(at: WidgetResources.bundle.bundleURL, to: packaged)
        let parent = try XCTUnwrap(Bundle(url: app))
        XCTAssertEqual(WidgetResources.resolve(in: parent).bundleURL.standardizedFileURL, packaged.standardizedFileURL)
    }
    @MainActor func testLowQuoteSurvivesFailureAndClearsOnlyOnConfirmedRecovery() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let model = WidgetModel(dataDirectory: root, resources: root)
        func snapshot(_ remaining: Double, query: Bool = true) throws -> Data {
            try JSONSerialization.data(withJSONObject: [
                "ok": true, "queryOk": query, "accountKey": "fixture-account",
                "observedAt": Date().timeIntervalSince1970*1000,
                "windows": [["minutes": 300, "remaining": remaining,
                             "resetsAt": Date().timeIntervalSince1970+3600]]
            ])
        }
        model.readSnapshot(try snapshot(4.9)); XCTAssertTrue(model.isLowQuota)
        model.showQuote(); XCTAssertEqual(model.message, "需要重置……")
        model.readSnapshot(try snapshot(100, query: false))
        XCTAssertTrue(model.isLowQuota); XCTAssertEqual(model.message, "需要重置……")
        model.readSnapshot(try snapshot(5))
        XCTAssertFalse(model.isLowQuota); XCTAssertNil(model.message); XCTAssertFalse(model.bubble)
    }
    @MainActor func testBundledPageActuallyStartsInWebKit() async throws {
        _ = NSApplication.shared
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let model = WidgetModel(dataDirectory: root, resources: root)
        let coordinator = WidgetWebCoordinator(model: model), view = coordinator.makeView()
        defer { coordinator.stop() }
        var loaded = false
        for _ in 0..<100 {
            let result = try? await view.browser.evaluateJavaScript("typeof window.GPTNiang")
            if result as? String == "object" { loaded = true; break }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTAssertTrue(loaded, "Bundled HTML, script and CSP must work with the custom URL scheme.")
    }
    @MainActor func testAnimatedEggsLoadThroughTheLocalSchemeAndRestoreTheMainCharacter() async throws {
        _ = NSApplication.shared
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let model = WidgetModel(dataDirectory: root, resources: root)
        let coordinator = WidgetWebCoordinator(model: model), view = coordinator.makeView()
        defer { model.finishEasterEgg(); coordinator.stop() }
        for _ in 0..<100 {
            if model.webViewReady { break }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        for (egg, expected) in [(EasterEgg.dance, 950), (.zero, 500)] {
            XCTAssertTrue(model.playEasterEgg(egg))
            coordinator.update()
            var width = 0
            for _ in 0..<100 {
                let result = try? await view.browser.evaluateJavaScript("document.getElementById('egg-portrait').naturalWidth")
                width = (result as? NSNumber)?.intValue ?? 0
                if width == expected { break }
                try await Task.sleep(nanoseconds: 50_000_000)
            }
            XCTAssertEqual(width, expected, "The local transparent GIF must decode in WebKit.")
        }
        model.finishEasterEgg(); coordinator.update()
        try await Task.sleep(nanoseconds: 100_000_000)
        let active = try await view.browser.evaluateJavaScript("document.getElementById('stage').classList.contains('is-easter-egg')")
        XCTAssertEqual(active as? Bool, false)
    }
    @MainActor func testTrackpadTapCompletesPressAndReceivesSavedAnimationOptions() async throws {
        _ = NSApplication.shared
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let model = WidgetModel(dataDirectory: root, resources: root)
        let coordinator = WidgetWebCoordinator(model: model), view = coordinator.makeView()
        defer { coordinator.stop() }
        for _ in 0..<100 {
            if model.webViewReady { break }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTAssertTrue(model.webViewReady)
        let held = try await view.browser.evaluateJavaScript("window.GPTNiang.press(true); window.GPTNiang.press(false); document.getElementById('stage').classList.contains('pressed')")
        XCTAssertEqual(held as? Bool, true, "Even same-frame down/up must reach a visible pressed state.")
        var released = false
        for _ in 0..<100 {
            try await Task.sleep(nanoseconds: 25_000_000)
            let active = try await view.browser.evaluateJavaScript("document.getElementById('stage').classList.contains('pressed')")
            if active as? Bool == false { released = true; break }
        }
        XCTAssertTrue(released, "A short tap must rebound and finish without another click.")
        model.pressAnimationSpeed = 2; model.pressImmediate = true; coordinator.update()
        let duration = try await view.browser.evaluateJavaScript("document.getElementById('stage').style.getPropertyValue('--press-in')")
        XCTAssertEqual(duration as? String, "0ms")
    }
    func testBridgeRejectsUnlistedCommandsAndExtraArguments() {
        XCTAssertEqual(WidgetWebPolicy.action(["action": "refresh"]), "refresh")
        XCTAssertNil(WidgetWebPolicy.action(["action": "exec", "command": "id"]))
        XCTAssertNil(WidgetWebPolicy.action(["action": "settings", "path": "/etc/passwd"]))
        XCTAssertNil(WidgetWebPolicy.action("refresh"))
        XCTAssertFalse(WidgetWebPolicy.isEntry(URL(string: "https://example.com/index.html")))
        XCTAssertFalse(WidgetWebPolicy.isEntry(URL(string: "gpt-niang://widget/index.html?next=remote")))
    }
    func testAssetHandlerCannotReadArbitraryFiles() {
        let root = URL(fileURLWithPath: "/bundle/WebWidget")
        let handler = WidgetAssetHandler(root: root, normal: root.appendingPathComponent("normal.png"), low: root.appendingPathComponent("low.png"))
        XCTAssertEqual(handler.resource(URL(string: "gpt-niang://widget/widget.js")!)?.0.lastPathComponent, "widget.js")
        XCTAssertNotNil(handler.resource(URL(string: "gpt-niang://widget/low.png?revision=12")!))
        XCTAssertEqual(handler.resource(URL(string: "gpt-niang://widget/egg-zero.gif?revision=12")!)?.0.lastPathComponent, "egg-zero.gif")
        for url in ["file:///etc/passwd", "gpt-niang://evil/widget.js", "gpt-niang://widget/secret.txt",
                    "gpt-niang://user@widget/index.html", "gpt-niang://widget/low.png?path=/etc/passwd"] {
            XCTAssertNil(handler.resource(URL(string: url)!))
        }
    }
    @MainActor func testWindowShrinksWithoutChangingLogicalCanvasOrSavedPosition() {
        _ = NSApplication.shared
        let panel = WidgetPanel(contentRect: CGRect(x: 100, y: 100, width: 378, height: 378),
                                styleMask: [.borderless], backing: .buffered, defer: false)
        panel.install(NSView(frame: CGRect(x: 0, y: 0, width: 378, height: 378)))
        let full = CGRect(x: 100, y: 100, width: 378, height: 378)
        panel.setVisibleContent(CGRect(x: 156, y: 14, width: 208, height: 208))
        XCTAssertTrue(panel.place(full, clippedTo: nil))
        XCTAssertEqual(panel.frame, CGRect(x: 256, y: 114, width: 208, height: 208))
        XCTAssertEqual(panel.placementFrame, full)
        panel.setVisibleContent(CGRect(x: 0, y: 0, width: 378, height: 378))
        XCTAssertEqual(panel.frame, full)
        panel.orderOut(nil)
    }
    @MainActor func testAlphaMaskRejectsTransparentPixels() throws {
        let bitmap = try XCTUnwrap(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 8, pixelsHigh: 8,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0))
        for y in 0..<8 { for x in 0..<8 {
            let opaque = x >= 4 && y >= 4
            var pixel = [opaque ? 255 : 0, 0, 0, opaque ? 255 : 0]
            bitmap.setPixel(&pixel, atX: x, y: y)
        } }
        let image = NSImage(size: CGSize(width: 8, height: 8)); image.addRepresentation(bitmap)
        let mask = CharacterHitMask(image: image)
        XCTAssertFalse(mask.contains(CGPoint(x: 0.1, y: 0.5)))
        XCTAssertFalse(mask.contains(CGPoint(x: 0.9, y: 0.1)))
        XCTAssertTrue(mask.contains(CGPoint(x: 0.9, y: 0.9)))
        XCTAssertGreaterThanOrEqual(mask.normalizedBounds.minX, 0.45)
        XCTAssertGreaterThanOrEqual(mask.normalizedBounds.minY, 0.45)
    }
    func testOtherAppFullscreenHidesButCodexAndMaximizedWindowsDoNot() {
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        XCTAssertTrue(WidgetVisibilityPolicy.hideForFullscreen(frontmostBundle: "com.apple.Safari", companionActive: false, windows: [screen], screens: [screen]))
        XCTAssertFalse(WidgetVisibilityPolicy.hideForFullscreen(frontmostBundle: "com.openai.codex", companionActive: false, windows: [screen], screens: [screen]))
        XCTAssertFalse(WidgetVisibilityPolicy.hideForFullscreen(frontmostBundle: "com.apple.Safari", companionActive: false, windows: [screen.insetBy(dx: 0, dy: 28)], screens: [screen]))
        XCTAssertFalse(WidgetVisibilityPolicy.hideForFullscreen(frontmostBundle: "widget", companionActive: true, windows: [screen], screens: [screen]))
    }
    @MainActor func testCharacterAndMenuBarPreferencesSurviveRestart() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let model = WidgetModel(dataDirectory: root, resources: root)
        model.menuBarOnly = true; model.hideInFullscreen = false; model.lowQuotaQuote = "需要休息"
        model.savePreferences()
        let restored = WidgetModel(dataDirectory: root, resources: root)
        XCTAssertTrue(restored.menuBarOnly); XCTAssertFalse(restored.hideInFullscreen)
        XCTAssertEqual(restored.lowQuotaQuote, "需要休息")
    }
}
