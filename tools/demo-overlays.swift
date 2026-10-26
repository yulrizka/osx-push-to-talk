// Draws the overlay images for tools/demo.sh at 2x: the pressed hotkey keycap and one pill per subtitle.
// Usage: demo-overlays <output dir> <key glyph> <key label, may be empty> <subtitle>...
import AppKit

let out = URL(fileURLWithPath: CommandLine.arguments[1])
let keyGlyph = CommandLine.arguments[2]
let keyLabel = CommandLine.arguments[3]

func png(_ name: String, _ size: NSSize, _ draw: () -> Void) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width * 2), pixelsHigh: Int(size.height * 2),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: out.appendingPathComponent(name))
}

func text(_ string: String, _ size: CGFloat, _ weight: NSFont.Weight, _ color: NSColor) -> NSAttributedString {
    NSAttributedString(string: string, attributes: [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color])
}

let keySize = NSSize(width: 84, height: 60)
png("key.png", keySize) {
    let path = NSBezierPath(roundedRect: NSRect(origin: .zero, size: keySize).insetBy(dx: 1, dy: 1), xRadius: 11, yRadius: 11)
    NSColor.white.withAlphaComponent(0.92).setFill()
    path.fill()
    NSColor.white.withAlphaComponent(0.35).setStroke()
    path.stroke()
    let glyph = text(keyGlyph, 22, .regular, .black)
    glyph.draw(at: NSPoint(x: (keySize.width - glyph.size().width) / 2, y: keyLabel.isEmpty ? (keySize.height - glyph.size().height) / 2 : 24))
    let label = text(keyLabel, 10, .medium, .black)
    label.draw(at: NSPoint(x: (keySize.width - label.size().width) / 2, y: 8))
}
for (index, subtitle) in CommandLine.arguments.dropFirst(4).enumerated() {
    let label = text(subtitle, 15, .medium, .white)
    let size = NSSize(width: ceil(label.size().width) + 28, height: 30)
    png("sub-\(index + 1).png", size) {
        NSColor.black.withAlphaComponent(0.6).setFill()
        NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 15, yRadius: 15).fill()
        label.draw(at: NSPoint(x: 14, y: (size.height - label.size().height) / 2))
    }
}
