import AppKit

func color(_ hex: UInt32) -> NSColor {
    NSColor(
        red: CGFloat((hex >> 16) & 255) / 255,
        green: CGFloat((hex >> 8) & 255) / 255,
        blue: CGFloat(hex & 255) / 255,
        alpha: 1
    )
}

func render(size: Int) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false,
        isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: size * 4, bitsPerPixel: 32
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "IconGenerator", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "Cannot create icon bitmap"])
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    let scale = CGFloat(size) / 1024
    context.cgContext.scaleBy(x: scale, y: scale)
    color(0x203D19).setFill()
    NSRect(x: 0, y: 0, width: 1024, height: 1024).fill()

    let tile = NSBezierPath(
        roundedRect: NSRect(x: 12, y: 12, width: 1000, height: 1000),
        xRadius: 210, yRadius: 210
    )
    guard let background = NSGradient(colors: [
        color(0x153B16), color(0x287B27), color(0x49F578)
    ]),
          let leafGradient = NSGradient(starting: color(0x318E20), ending: color(0xB1E833)) else {
        throw NSError(domain: "IconGenerator", code: 2,
                      userInfo: [NSLocalizedDescriptionKey: "Cannot create icon gradients"])
    }
    background.draw(in: tile, angle: 90)
    NSGraphicsContext.saveGraphicsState()
    tile.addClip()
    let rim = NSBezierPath(
        roundedRect: NSRect(x: 22, y: 22, width: 980, height: 980),
        xRadius: 200, yRadius: 200
    )
    NSColor.white.withAlphaComponent(0.2).setStroke()
    rim.lineWidth = 5
    rim.stroke()
    NSGraphicsContext.restoreGraphicsState()

    let stem = NSBezierPath()
    stem.move(to: NSPoint(x: 485, y: 515))
    stem.curve(to: NSPoint(x: 383, y: 187),
               controlPoint1: NSPoint(x: 516, y: 357),
               controlPoint2: NSPoint(x: 473, y: 237))
    stem.lineWidth = 38
    stem.lineCapStyle = .round
    color(0x64C62D).setStroke()
    stem.stroke()

    for angle in [0.0, 90.0, 180.0, 270.0] {
        NSGraphicsContext.saveGraphicsState()
        let matrix = NSAffineTransform()
        matrix.translateX(by: 480, yBy: 550)
        matrix.rotate(byDegrees: CGFloat(angle))
        matrix.concat()
        let leaf = NSBezierPath()
        leaf.move(to: NSPoint(x: -20, y: 20))
        leaf.line(to: NSPoint(x: -174, y: 20))
        leaf.curve(to: NSPoint(x: -302, y: 153),
                   controlPoint1: NSPoint(x: -261, y: 20),
                   controlPoint2: NSPoint(x: -302, y: 65))
        leaf.curve(to: NSPoint(x: -159, y: 315),
                   controlPoint1: NSPoint(x: -302, y: 250),
                   controlPoint2: NSPoint(x: -246, y: 315))
        leaf.curve(to: NSPoint(x: -20, y: 171),
                   controlPoint1: NSPoint(x: -68, y: 315),
                   controlPoint2: NSPoint(x: -20, y: 272))
        leaf.line(to: NSPoint(x: -20, y: 20))
        leaf.close()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
        shadow.shadowOffset = NSSize(width: 0, height: -7)
        shadow.shadowBlurRadius = 10
        shadow.set()
        leafGradient.draw(in: leaf, angle: CGFloat(90 - angle))
        NSGraphicsContext.restoreGraphicsState()
    }

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.2)
    shadow.shadowOffset = NSSize(width: 0, height: -7)
    shadow.shadowBlurRadius = 12
    shadow.set()
    let gear = NSBezierPath()
    let center = NSPoint(x: 745, y: 292)
    for step in 0..<80 {
        let angle = CGFloat(step) * .pi * 2 / 80
        let radius: CGFloat = [0, 3].contains(step % 8) || step % 8 > 3 ? 143 : 167
        let point = NSPoint(x: center.x + cos(angle) * radius,
                            y: center.y + sin(angle) * radius)
        if step == 0 { gear.move(to: point) } else { gear.line(to: point) }
    }
    gear.close()
    NSColor.white.setFill()
    gear.fill()
    NSGraphicsContext.restoreGraphicsState()

    let disc = NSBezierPath(ovalIn: NSRect(x: 637, y: 184, width: 216, height: 216))
    color(0x1B573A).setFill()
    disc.fill()
    let check = NSBezierPath()
    check.move(to: NSPoint(x: 682, y: 289))
    check.line(to: NSPoint(x: 727, y: 245))
    check.line(to: NSPoint(x: 808, y: 337))
    check.lineWidth = 24
    check.lineCapStyle = .round
    check.lineJoinStyle = .round
    NSColor.white.setStroke()
    check.stroke()

    NSGraphicsContext.restoreGraphicsState()
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGenerator", code: 3,
                      userInfo: [NSLocalizedDescriptionKey: "Cannot encode PNG"])
    }
    return data
}

guard CommandLine.arguments.count == 2 else {
    fatalError("Usage: swift macOS/Tools/GenerateIcon.swift macOS/Resources")
}
let resources = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let iconset = resources.appendingPathComponent("AppIcon.iconset", isDirectory: true)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    for multiplier in [1, 2] {
        let suffix = multiplier == 2 ? "@2x" : ""
        try render(size: base * multiplier).write(
            to: iconset.appendingPathComponent("icon_\(base)x\(base)\(suffix).png")
        )
    }
}
try render(size: 1024).write(to: resources.appendingPathComponent("AppIcon.png"))
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = [
    "-c", "icns", iconset.path, "-o", resources.appendingPathComponent("AppIcon.icns").path
]
try process.run()
process.waitUntilExit()
guard process.terminationStatus == 0 else {
    throw NSError(domain: "IconGenerator", code: Int(process.terminationStatus),
                  userInfo: [NSLocalizedDescriptionKey: "iconutil failed"])
}
print("Created AppIcon.png, AppIcon.iconset and AppIcon.icns in \(resources.path)")
