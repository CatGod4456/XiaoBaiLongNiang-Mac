import XCTest
import AppKit
import GPTNiangCore
import ImageIO
@testable import GPTNiangMac

final class EasterEggTests: XCTestCase {
    @MainActor func testGIFResourcesMatchThePlaybackDurationsWithoutIntrinsicLoops() throws {
        let data = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: data) }
        let model = WidgetModel(dataDirectory: data, resources: data)
        for (egg, count) in [(EasterEgg.dance, 70), (.zero, 98)] {
            let source = try XCTUnwrap(CGImageSourceCreateWithURL(model.easterEggURL(egg) as CFURL, nil))
            XCTAssertEqual(CGImageSourceGetCount(source), count)
            let properties = CGImageSourceCopyProperties(source, nil) as? [CFString: Any]
            let gif = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            // ImageIO reports a single play as 1 even without a loop extension.
            XCTAssertEqual((gif?[kCGImagePropertyGIFLoopCount] as? NSNumber)?.intValue ?? 1, 1)
            var duration = 0.0
            for index in 0..<count {
                let frame = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
                let values = frame?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
                duration += (values?[kCGImagePropertyGIFUnclampedDelayTime] as? Double) ?? (values?[kCGImagePropertyGIFDelayTime] as? Double) ?? 0
            }
            XCTAssertEqual(duration, egg.duration, accuracy: 0.001)
        }
    }
    func testEggsShareFivePercentAndTheRestUseTheNormalClick() {
        XCTAssertEqual(EasterEgg.select(draw: 0, danceAvailable: true), .squish)
        XCTAssertEqual(EasterEgg.select(draw: 0.024999, danceAvailable: true), .squish)
        XCTAssertEqual(EasterEgg.select(draw: 0.025, danceAvailable: true), .dance)
        XCTAssertEqual(EasterEgg.select(draw: 0.049999, danceAvailable: true), .dance)
        XCTAssertNil(EasterEgg.select(draw: 0.05, danceAvailable: true))
        XCTAssertNil(EasterEgg.select(draw: 0.06, danceAvailable: false))
        XCTAssertNil(EasterEgg.select(draw: 0.04, danceAvailable: false))
        XCTAssertNil(EasterEgg.select(draw: .nan, danceAvailable: true))
        XCTAssertNil(EasterEgg.select(draw: 0.01, danceAvailable: true, squishEnabled: false))
        XCTAssertNil(EasterEgg.select(draw: 0.03, danceAvailable: true, danceEnabled: false))
    }
    func testZeroQuotaSplitsTheSameFivePercentIntoThreeFixedIntervals() {
        let width = 0.05 / 3
        XCTAssertEqual(EasterEgg.select(draw: 0, danceAvailable: true, zeroQuota: true, zeroAvailable: true), .squish)
        XCTAssertEqual(EasterEgg.select(draw: width, danceAvailable: true, zeroQuota: true, zeroAvailable: true), .dance)
        XCTAssertEqual(EasterEgg.select(draw: 2 * width, danceAvailable: true, zeroQuota: true, zeroAvailable: true), .zero)
        XCTAssertEqual(EasterEgg.select(draw: 0.049999, danceAvailable: true, zeroQuota: true, zeroAvailable: true), .zero)
        XCTAssertNil(EasterEgg.select(draw: 0.05, danceAvailable: true, zeroQuota: true, zeroAvailable: true))
        XCTAssertNil(EasterEgg.select(draw: 0.04, danceAvailable: true, zeroQuota: true, zeroAvailable: true, zeroEnabled: false))
        XCTAssertNil(EasterEgg.select(draw: 0.04, danceAvailable: true, zeroQuota: true, zeroAvailable: false))
        XCTAssertNil(EasterEgg.select(draw: 0.02, danceAvailable: true, danceEnabled: false, zeroQuota: true, zeroAvailable: true))
        var counts: [EasterEgg: Int] = [:]
        for i in 0..<60_000 {
            if let egg = EasterEgg.select(draw: (Double(i) + 0.5) / 60_000, danceAvailable: true, zeroQuota: true, zeroAvailable: true) {
                counts[egg, default: 0] += 1
            }
        }
        XCTAssertEqual(counts[.squish], 1000); XCTAssertEqual(counts[.dance], 1000); XCTAssertEqual(counts[.zero], 1000)
    }
    func testZeroRequiresCurrentValidUnexpiredDataAndAnExactZero() {
        let now = Date(timeIntervalSince1970: 10_000)
        func sample(_ values: [Double], age: Double = 0, reset: Double = 11_000, ok: Bool = true, query: Bool = true) -> UsageSnapshot {
            UsageSnapshot(ok: ok, queryOk: query, observedAt: (now.timeIntervalSince1970 - age) * 1000,
                          windows: values.enumerated().map { QuotaWindow(minutes: 300 * ($0.offset + 1), remaining: $0.element, resetsAt: reset) })
        }
        XCTAssertTrue(EasterEgg.zeroEligible(sample([0, 89]), at: now))
        XCTAssertFalse(EasterEgg.zeroEligible(sample([0.01, 89]), at: now))
        XCTAssertFalse(EasterEgg.zeroEligible(sample([0], age: 181), at: now))
        XCTAssertFalse(EasterEgg.zeroEligible(sample([0], age: -6), at: now))
        XCTAssertFalse(EasterEgg.zeroEligible(sample([0], reset: 9999), at: now))
        XCTAssertFalse(EasterEgg.zeroEligible(sample([0], ok: false), at: now))
        XCTAssertFalse(EasterEgg.zeroEligible(sample([0], query: false), at: now))
        XCTAssertFalse(EasterEgg.zeroEligible(sample([0, 101]), at: now))
        XCTAssertFalse(EasterEgg.zeroEligible(sample([]), at: now))
    }
    @MainActor func testZeroPreviewPersistenceAndAutomaticSelectionGate() throws {
        let data = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: data) }
        let model = WidgetModel(dataDirectory: data, resources: data)
        defer { model.finishEasterEgg() }
        model.characterClick(draw: 0.04)
        XCTAssertEqual(model.easterEgg, .dance) // Unknown quota cannot select zero.
        model.finishEasterEgg()
        model.snapshot = UsageSnapshot(ok: true, queryOk: true, observedAt: Date().timeIntervalSince1970 * 1000,
                                       windows: [QuotaWindow(minutes: 300, remaining: 0)])
        model.characterClick(draw: 0.04); XCTAssertEqual(model.easterEgg, .zero)
        model.zeroLoops = 4; model.zeroEnabled = false; model.saveEasterEggPreferences()
        let restored = WidgetModel(dataDirectory: data, resources: data)
        defer { restored.finishEasterEgg() }
        XCTAssertEqual(restored.zeroLoops, 4); XCTAssertFalse(restored.zeroEnabled)
        restored.zeroEnabled = true
        XCTAssertTrue(restored.playEasterEgg(.zero)) // Explicit preview works without zero quota.
        restored.characterClick(draw: 0.04); XCTAssertNil(restored.easterEgg)
    }
    @MainActor func testEggRestoresAutomaticallyAndAClickCanCancelIt() async throws {
        let data = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: data) }
        let model = WidgetModel(dataDirectory: data, resources: data)
        model.characterClick(draw: 0.01)
        XCTAssertEqual(model.easterEgg, .squish)
        try await Task.sleep(nanoseconds: 2_600_000_000)
        XCTAssertNil(model.easterEgg)
        model.characterClick(draw: 0.01)
        XCTAssertEqual(model.easterEgg, .squish)
        model.characterClick(draw: 0.5)
        XCTAssertNil(model.easterEgg)
        XCTAssertTrue(model.bubble)
    }
    @MainActor func testSwitchesAndLoopCountsPersistAndContinuousPlaybackCanBeStopped() async throws {
        let data = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: data) }
        let model = WidgetModel(dataDirectory: data, resources: data)
        model.squishLoops = 0; model.danceLoops = 4; model.danceEnabled = false
        model.saveEasterEggPreferences()
        let restored = WidgetModel(dataDirectory: data, resources: data)
        XCTAssertEqual(restored.squishLoops, 0); XCTAssertEqual(restored.danceLoops, 4)
        XCTAssertFalse(restored.danceEnabled)
        XCTAssertFalse(restored.playEasterEgg(.dance))
        XCTAssertTrue(restored.playEasterEgg(.squish))
        try await Task.sleep(nanoseconds: 1_000_000_000)
        XCTAssertEqual(restored.easterEgg, .squish)
        restored.easterEggsEnabled = false; restored.saveEasterEggPreferences()
        XCTAssertNil(restored.easterEgg)
        restored.characterClick(draw: 0.01); XCTAssertNil(restored.easterEgg)
        XCTAssertFalse(WidgetModel(dataDirectory: data, resources: data).easterEggsEnabled)
    }
    @MainActor func testDanceReplaysOnlyTheSelectedNumberOfCycles() async throws {
        let data = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: data) }
        let model = WidgetModel(dataDirectory: data, resources: data)
        model.danceLoops = 2
        XCTAssertTrue(model.playEasterEgg(.dance))
        let generation = model.easterEggGeneration
        try await Task.sleep(nanoseconds: UInt64((EasterEgg.dance.duration + 0.3) * 1_000_000_000))
        XCTAssertEqual(model.easterEgg, .dance)
        XCTAssertGreaterThan(model.easterEggGeneration, generation)
        try await Task.sleep(nanoseconds: UInt64((EasterEgg.dance.duration + 0.3) * 1_000_000_000))
        XCTAssertNil(model.easterEgg)
    }
}
