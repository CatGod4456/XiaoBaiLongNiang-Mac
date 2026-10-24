import Foundation

/// Changes character only on confirmed, current quota data. A clock reaching a
/// reset time is not evidence that a server has replenished the account.
public struct LowQuotaState {
    public private(set) var isLow = false
    private var accountKey: String?
    private var lastObservation: Double?
    public init() {}

    @discardableResult
    public mutating func update(_ snapshot: UsageSnapshot, enabled: Bool = true, at now: Date = Date()) -> Bool {
        if !enabled || accountKey != snapshot.accountKey {
            isLow = false; lastObservation = nil; accountKey = snapshot.accountKey
        }
        guard enabled, !snapshot.stale(at: now), let observation = snapshot.observedAt,
              lastObservation.map({ observation >= $0 }) ?? true else { return isLow }
        let windows = snapshot.validWindows
        guard !windows.isEmpty, windows.count == snapshot.windows.count else { return isLow }
        lastObservation = observation
        if windows.contains(where: { !$0.expired(at: now) && $0.remaining < 5 }) {
            isLow = true
        } else if windows.allSatisfy({ !$0.expired(at: now) && $0.remaining >= 5 }) {
            isLow = false
        }
        return isLow
    }
}
