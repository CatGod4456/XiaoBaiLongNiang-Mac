import XCTest
import AppKit
import GPTNiangCore
@testable import GPTNiangMac

final class MenuBarPresentationTests: XCTestCase {
    func testCurrentQuotaStaysVisibleAndIncludesBothWindows() {
        let now = Date()
        let snapshot = UsageSnapshot(ok: true, queryOk: true, observedAt: now.timeIntervalSince1970 * 1000,
            windows: [QuotaWindow(minutes: 10080, remaining: 93), QuotaWindow(minutes: 300, remaining: 0)])
        XCTAssertEqual(MenuBarPresentation.quotaTitle(snapshot, now: now), " 0% / 93%")
        XCTAssertEqual(MenuBarPresentation.quotaTitle(snapshot, now: now.addingTimeInterval(200)), " …")
    }
    @MainActor func testMenuIconUsesTheCharacterAndKeepsTheSourceSize() {
        let image = NSImage(size: CGSize(width: 1536, height: 1536))
        let icon = MenuBarPresentation.characterIcon(image)
        XCTAssertEqual(icon?.size, CGSize(width: 20, height: 20))
        XCTAssertFalse(icon?.isTemplate ?? true)
        XCTAssertEqual(image.size, CGSize(width: 1536, height: 1536))
    }
}
