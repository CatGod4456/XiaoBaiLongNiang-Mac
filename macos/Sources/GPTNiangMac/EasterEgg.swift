import Foundation

enum EasterEgg: String {
    case squish, dance
    var filename: String { self == .squish ? "egg-squish.png" : "egg-dance.gif" }
    var duration: TimeInterval { self == .squish ? 0.8 : 4.55 }
    static func select(draw: Double, danceAvailable: Bool, squishEnabled: Bool = true, danceEnabled: Bool = true) -> EasterEgg? {
        guard draw.isFinite, draw >= 0 else { return nil }
        if draw < 0.025 && squishEnabled { return .squish }
        if draw >= 0.025 && draw < 0.05 && danceAvailable && danceEnabled { return .dance }
        return nil
    }
}
