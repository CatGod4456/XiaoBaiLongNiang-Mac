import XCTest
import GPTNiangCore

final class LowQuotaTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 10000)
    private func sample(_ remaining: [Double], account: String? = "a", at: Double = 10000000,
                        ok: Bool = true, query: Bool = true, reset: Double = 11000) -> UsageSnapshot {
        UsageSnapshot(ok: ok, queryOk: query, observedAt: at,
            windows: remaining.enumerated().map { QuotaWindow(minutes: ($0.offset+1)*300, remaining: $0.element, resetsAt: reset) },
            accountKey: account)
    }
    func testStrictThresholdAnyWindowAndConfirmedRecovery() {
        var state = LowQuotaState()
        XCTAssertFalse(state.update(sample([5, 80]), at: now))
        XCTAssertTrue(state.update(sample([80, 4.9]), at: now))
        XCTAssertTrue(state.update(sample([0, 100]), at: now))
        XCTAssertFalse(state.update(sample([5, 100]), at: now))
    }
    func testFailedOrOldHighSnapshotNeverInventsRecovery() {
        var state = LowQuotaState()
        state.update(sample([1]), at: now)
        XCTAssertTrue(state.update(sample([100], ok: false, query: false), at: now))
        XCTAssertTrue(state.update(sample([100], at: 9000000), at: now))
        XCTAssertTrue(state.update(sample([100], at: 10001000), at: now.addingTimeInterval(200)))
        XCTAssertTrue(state.update(sample([100], at: 10010000), at: now)) // Future clock.
    }
    func testResetClockAndAnEmptyOrMalformedWindowDoNotRestore() {
        var state = LowQuotaState()
        state.update(sample([1]), at: now)
        XCTAssertTrue(state.update(sample([100], reset: 9999), at: now))
        XCTAssertTrue(state.update(sample([]), at: now))
        XCTAssertTrue(state.update(sample([100, 101]), at: now))
        XCTAssertFalse(state.update(sample([100], at: 10001000), at: now.addingTimeInterval(1)))
    }
    func testNewAccountOrLostIdentityCannotInheritLowCharacter() {
        var state = LowQuotaState()
        state.update(sample([1]), at: now)
        XCTAssertFalse(state.update(sample([], account: "b", ok: false, query: false), at: now))
        XCTAssertTrue(state.update(sample([0], account: "b"), at: now))
        XCTAssertFalse(state.update(sample([], account: nil, ok: false, query: false), at: now))
    }
    func testDisabledFeatureAndOutOfOrderSnapshots() {
        var state = LowQuotaState()
        state.update(sample([0], at: 10001000), at: now.addingTimeInterval(1))
        XCTAssertTrue(state.update(sample([90]), at: now.addingTimeInterval(1)))
        XCTAssertFalse(state.update(sample([0]), enabled: false, at: now))
        XCTAssertTrue(state.update(sample([0]), enabled: true, at: now))
    }
}
