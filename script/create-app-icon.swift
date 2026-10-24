import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let source = URL(fileURLWithPath: CommandLine.arguments[1])
let directory = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
guard let imageSource = CGImageSourceCreateWithURL(source as CFURL, nil),
      let character = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else { fatalError("Cannot read character icon source") }
let colorSpace = CGColorSpaceCreateDeviceRGB()
func context(_ size: Int) -> CGContext {
    guard let result = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
        bytesPerRow: size * 4, space: colorSpace,
        bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue) else { fatalError("Cannot allocate icon") }
    result.interpolationQuality = .high
    return result
}
let canvas = context(1024)
let card = CGRect(x: 48, y: 48, width: 928, height: 928)
let outline = CGPath(roundedRect: card, cornerWidth: 208, cornerHeight: 208, transform: nil)
canvas.saveGState()
canvas.setShadow(offset: CGSize(width: 0, height: -7), blur: 22,
    color: CGColor(red: 0.25, green: 0.18, blue: 0.38, alpha: 0.24))
canvas.addPath(outline); canvas.setFillColor(CGColor(gray: 1, alpha: 1)); canvas.fillPath()
canvas.restoreGState()
canvas.saveGState(); canvas.addPath(outline); canvas.clip()
let colors = [CGColor(red: 0.83, green: 0.78, blue: 0.94, alpha: 1),
              CGColor(red: 0.97, green: 0.95, blue: 1, alpha: 1)] as CFArray
let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!
canvas.drawLinearGradient(gradient, start: CGPoint(x: 512, y: 48), end: CGPoint(x: 512, y: 976), options: [])
let scale = min(card.width / CGFloat(character.width), card.height / CGFloat(character.height))
let size = CGSize(width: CGFloat(character.width) * scale, height: CGFloat(character.height) * scale)
canvas.draw(character, in: CGRect(x: 512 - size.width / 2, y: card.minY, width: size.width, height: size.height))
canvas.restoreGState()
canvas.addPath(outline); canvas.setStrokeColor(CGColor(gray: 1, alpha: 0.7)); canvas.setLineWidth(2); canvas.strokePath()
guard let master = canvas.makeImage() else { fatalError("Cannot render icon") }
for (name, size) in [("icon_16x16",16),("icon_16x16@2x",32),("icon_32x32",32),("icon_32x32@2x",64),
                     ("icon_128x128",128),("icon_128x128@2x",256),("icon_256x256",256),
                     ("icon_256x256@2x",512),("icon_512x512",512),("icon_512x512@2x",1024)] {
    let output = context(size)
    output.draw(master, in: CGRect(x: 0, y: 0, width: size, height: size))
    let file = directory.appendingPathComponent(name + ".png")
    guard let destination = CGImageDestinationCreateWithURL(file as CFURL, UTType.png.identifier as CFString, 1, nil),
          let image = output.makeImage() else { fatalError("Cannot write icon") }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { fatalError("Cannot save icon") }
}
