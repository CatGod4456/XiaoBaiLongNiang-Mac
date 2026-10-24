import Foundation
import GPTNiangCore

enum EasterEgg: String {
    case squish, dance, zero
    var filename: String {
        switch self {
        case .squish: return "egg-squish.png"
        case .dance: return "egg-dance.gif"
        case .zero: return "egg-zero.gif"
        }
    }
    var duration: TimeInterval {
        switch self {
        case .squish: return 0.8
        case .dance: return 7
        case .zero: return 9.8
        }
    }
    static func zeroEligible(_ snapshot: UsageSnapshot, at now: Date = Date()) -> Bool {
        guard !snapshot.stale(at: now), !snapshot.windows.isEmpty,
              snapshot.validWindows.count == snapshot.windows.count else { return false }
        return snapshot.validWindows.contains { !$0.expired(at: now) && $0.remaining == 0 }
    }
    static func select(draw: Double, danceAvailable: Bool, squishEnabled: Bool = true, danceEnabled: Bool = true,
                       zeroQuota: Bool = false, zeroAvailable: Bool = false, zeroEnabled: Bool = true) -> EasterEgg? {
        guard draw.isFinite, draw >= 0, draw < 0.05 else { return nil }
        let width = 0.05 / (zeroQuota ? 3 : 2)
        if draw < width { return squishEnabled ? .squish : nil }
        if draw < width * 2 { return danceAvailable && danceEnabled ? .dance : nil }
        return zeroQuota && zeroAvailable && zeroEnabled ? .zero : nil
    }
}
