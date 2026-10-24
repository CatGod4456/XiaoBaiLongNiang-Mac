import AppKit
import ImageIO
import UniformTypeIdentifiers

enum CharacterVariant: String { case normal, low }

/// Only decoded raster images reach WebKit. User filenames never become URLs.
@MainActor final class CharacterImageStore {
    private let data: URL
    private let resources: URL
    private(set) var names: [CharacterVariant: String] = [:]
    private var images: [CharacterVariant: NSImage] = [:]
    init(data: URL, resources: URL, normal: String?, low: String?) {
        self.data = data; self.resources = resources
        for (variant, name) in [(CharacterVariant.normal, normal), (.low, low)] {
            if let name, Self.validName(name), Self.decoded(customURL(name)) != nil { names[variant] = name }
        }
        reload()
    }
    private static func validName(_ name: String) -> Bool {
        name.hasSuffix(".png") && UUID(uuidString: String(name.dropLast(4))) != nil
    }
    private func customURL(_ name: String) -> URL { data.appendingPathComponent("characters").appendingPathComponent(name) }
    func url(_ variant: CharacterVariant) -> URL {
        if let name = names[variant] { return customURL(name) }
        return resources.appendingPathComponent(variant == .low ? "gpt-dragon-niang-low-quota.png" : "gpt-dragon-niang-bust.png")
    }
    func image(_ variant: CharacterVariant) -> NSImage? { images[variant] ?? images[.normal] }
    private func reload() {
        for variant in [CharacterVariant.normal, .low] {
            images[variant] = Self.decoded(url(variant)).map { NSImage(cgImage: $0, size: CGSize(width: CGFloat($0.width), height: CGFloat($0.height))) }
        }
    }
    private static func decoded(_ url: URL) -> CGImage? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              ((attributes[.size] as? NSNumber)?.intValue ?? Int.max) <= 10 * 1024 * 1024,
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0, width <= 4096, height <= 4096 else { return nil }
        return CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 1536, kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true] as CFDictionary)
    }
    func choose(_ variant: CharacterVariant) throws -> Bool {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .webP]
        panel.allowsMultipleSelection = false; panel.canChooseDirectories = false
        panel.message = "选择形象图片。透明 PNG 的空白区域可穿透点击。"
        guard panel.runModal() == .OK, let source = panel.url else { return false }
        guard let image = Self.decoded(source),
              let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
            throw NSError(domain: "GPTNiangCharacter", code: 1, userInfo: [NSLocalizedDescriptionKey: "图片不可用。请选择不超过 10 MiB、4096 × 4096 的 PNG、JPEG 或 WebP。"])
        }
        let directory = data.appendingPathComponent("characters", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let name = UUID().uuidString + ".png", target = customURL(name)
        try png.write(to: target, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: target.path)
        let old = names[variant]; names[variant] = name; reload()
        if let old, Self.validName(old) { try? FileManager.default.removeItem(at: customURL(old)) }
        return true
    }
    func reset(_ variant: CharacterVariant) {
        let old = names.removeValue(forKey: variant); reload()
        if let old, Self.validName(old) { try? FileManager.default.removeItem(at: customURL(old)) }
    }
}

/// Small cached alpha grid for pointer hit testing, independent of image size.
@MainActor final class CharacterHitMask {
    private let side = 128
    private var alpha = [Bool](repeating: true, count: 128 * 128)
    let imageSize: CGSize
    private(set) var normalizedBounds = CGRect(x: 0, y: 0, width: 1, height: 1)
    init(image: NSImage?) {
        imageSize = image?.size ?? CGSize(width: 1, height: 1)
        guard let image, let bitmap = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        // Read a known RGBA format rather than TIFF colorAt(), whose decoded
        // color space can be unsupported on otherwise valid macOS images.
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        let drawn = pixels.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(data: bytes.baseAddress, width: side, height: side,
                bitsPerComponent: 8, bytesPerRow: side * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.interpolationQuality = .none
            context.draw(bitmap, in: CGRect(x: 0, y: 0, width: side, height: side))
            return true
        }
        guard drawn else { return }
        var minX = side, minY = side, maxX = -1, maxY = -1
        for y in 0..<side { for x in 0..<side {
            let visible = pixels[(y * side + x) * 4 + 3] > 20
            alpha[y * side + x] = visible
            if visible { minX = min(minX, x); minY = min(minY, y); maxX = max(maxX, x); maxY = max(maxY, y) }
        } }
        if maxX >= minX {
            normalizedBounds = CGRect(x: Double(minX)/Double(side), y: Double(minY)/Double(side),
                width: Double(maxX-minX+1)/Double(side), height: Double(maxY-minY+1)/Double(side))
        } else { normalizedBounds = .zero }
    }
    func contains(_ point: CGPoint) -> Bool {
        guard point.x >= 0, point.x < 1, point.y >= 0, point.y < 1 else { return false }
        return alpha[min(side-1, Int(point.y*CGFloat(side))) * side + min(side-1, Int(point.x*CGFloat(side)))]
    }
    func fitted(in box: CGRect) -> CGRect {
        let factor = min(box.width/max(1, imageSize.width), box.height/max(1, imageSize.height))
        let size = CGSize(width: imageSize.width*factor, height: imageSize.height*factor)
        return CGRect(x: box.midX-size.width/2, y: box.midY-size.height/2, width: size.width, height: size.height)
    }
}
