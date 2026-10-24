import XCTest
import AppKit
@testable import GPTNiangMac

final class EasterEggTests: XCTestCase {
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
        try await Task.sleep(nanoseconds: 4_850_000_000)
        XCTAssertEqual(model.easterEgg, .dance)
        XCTAssertGreaterThan(model.easterEggGeneration, generation)
        try await Task.sleep(nanoseconds: 4_850_000_000)
        XCTAssertNil(model.easterEgg)
    }
}
