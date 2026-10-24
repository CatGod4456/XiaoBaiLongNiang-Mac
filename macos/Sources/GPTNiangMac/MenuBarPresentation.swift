import AppKit
import GPTNiangCore

enum MenuBarPresentation {
    static func quotaTitle(_ snapshot: UsageSnapshot, now: Date = Date()) -> String {
        guard !snapshot.stale(at: now) else { return " …" }
        let windows = snapshot.displayWindows.filter { !$0.expired(at: now) }
        guard !windows.isEmpty else { return " …" }
        return " " + windows.map { $0.percentageText + "%" }.joined(separator: " / ")
    }

    @MainActor static func characterIcon(_ image: NSImage?) -> NSImage? {
        guard let icon = image?.copy() as? NSImage else { return nil }
        icon.size = CGSize(width: 20, height: 20)
        icon.isTemplate = false
        return icon
    }
}
