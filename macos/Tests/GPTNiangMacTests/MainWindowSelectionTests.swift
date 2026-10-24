import XCTest
import AppKit
@testable import GPTNiangMac

final class MainWindowSelectionTests: XCTestCase {
    func testFrontmostSmallPreviewCannotStealTheCompanionFromTheMainWindow() {
        let windows = [
            (frame: CGRect(x: 900, y: 100, width: 610, height: 480), number: 1),
            (frame: CGRect(x: 200, y: 100, width: 1494, height: 947), number: 2),
            (frame: CGRect(x: 1100, y: 300, width: 500, height: 700), number: 3)
        ]
        XCTAssertEqual(WindowFollowPolicy.prioritizeMainWindows(windows).map { $0.number }, [2, 3, 1])
        XCTAssertEqual(WindowFollowPolicy.prioritizeMainWindows(Array(windows.prefix(1))).first?.number, 1)
    }
    func testEqualMainWindowsRetainTheirFrontToBackOrder() {
        let frame = CGRect(x: 0, y: 0, width: 1200, height: 900)
        XCTAssertEqual(WindowFollowPolicy.prioritizeMainWindows([(frame, 7), (frame, 8)]).map { $0.number }, [7, 8])
    }
}
