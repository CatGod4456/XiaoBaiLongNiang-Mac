import AppKit
import GPTNiangCore

/// A fixed logical canvas inside a cropped native window. WindowServer clips
/// the viewport at display edges; the character and its pointer view never move
/// within, or shrink to fit, the remaining visible part of the host.
@MainActor
final class WidgetPanel: NSPanel {
    private let viewport = NSView()
    private var canvas: NSView?
    private var savedPlacement: CGRect?
    private var savedHost: CGRect?
    private var visibleContent: CGRect?
    var characterBottom: CGFloat?
    var interactiveAtScreenPoint: ((CGPoint) -> Bool)?
    var placementFrame: CGRect { savedPlacement ?? frame }

    func setVisibleContent(_ rect: CGRect) {
        guard visibleContent != rect else { return }
        visibleContent = rect
        if let savedPlacement { _ = place(savedPlacement, clippedTo: savedHost) }
    }
    func updateMousePassthrough(captured: Bool) {
        guard let interactiveAtScreenPoint else { return }
        let ignore = !captured && !interactiveAtScreenPoint(NSEvent.mouseLocation)
        if ignoresMouseEvents != ignore { ignoresMouseEvents = ignore }
    }

    func install(_ content: NSView) {
        canvas?.removeFromSuperview()
        viewport.autoresizesSubviews = false
        viewport.wantsLayer = true
        viewport.layer?.masksToBounds = true
        content.autoresizingMask = []
        canvas = content
        contentView = viewport
        content.frame = viewport.bounds
        viewport.addSubview(content)
    }

    /// Cropping never writes preferences or changes window order/level.
    @discardableResult
    func place(_ desired: CGRect, clippedTo host: CGRect?) -> Bool {
        savedHost = host
        let content = visibleContent.map { CGRect(x: desired.minX+$0.minX, y: desired.minY+$0.minY, width: $0.width, height: $0.height) } ?? desired
        let clip = host.map { $0.intersection(content) } ?? content
        guard let visible = WidgetPlacement.viewport(frame: desired, host: clip),
              let canvas else { orderOut(nil); return false }
        savedPlacement = desired
        if frame != visible { setFrame(visible, display: false) }
        let contentFrame = CGRect(x: desired.minX - visible.minX,
                                  y: desired.minY - visible.minY,
                                  width: desired.width, height: desired.height)
        if canvas.frame != contentFrame { canvas.frame = contentFrame }
        return true
    }
}
