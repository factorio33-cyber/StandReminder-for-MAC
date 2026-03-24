import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    fputs("Usage: swift generate_app_icon.swift /path/to/output.png\n", stderr)
    exit(1)
}

let outputURL = URL(fileURLWithPath: arguments[1])
let pixelSize = 1024

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: pixelSize,
    pixelsHigh: pixelSize,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("Unable to allocate bitmap.\n", stderr)
    exit(1)
}

guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fputs("Unable to create graphics context.\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphicsContext
defer { NSGraphicsContext.restoreGraphicsState() }

let context = graphicsContext.cgContext
let canvas = NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize)

context.setAllowsAntialiasing(true)
context.setShouldAntialias(true)
context.interpolationQuality = .high

NSColor.clear.setFill()
canvas.fill()

let iconRect = canvas.insetBy(dx: 44, dy: 44)
let iconPath = NSBezierPath(roundedRect: iconRect, xRadius: 226, yRadius: 226)

func drawShadow(_ color: NSColor, blur: CGFloat, offset: NSSize) {
    let shadow = NSShadow()
    shadow.shadowColor = color
    shadow.shadowBlurRadius = blur
    shadow.shadowOffset = offset
    shadow.set()
}

context.saveGState()
drawShadow(NSColor(calibratedWhite: 0, alpha: 0.20), blur: 34, offset: NSSize(width: 0, height: -14))
let backgroundGradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.07, green: 0.15, blue: 0.28, alpha: 1),
    NSColor(calibratedRed: 0.12, green: 0.37, blue: 0.53, alpha: 1),
    NSColor(calibratedRed: 0.30, green: 0.72, blue: 0.72, alpha: 1),
])!
backgroundGradient.draw(in: iconPath, angle: -36)
context.restoreGState()

context.saveGState()
iconPath.addClip()

let upperGlowRect = NSRect(x: 48, y: 610, width: 630, height: 340)
let upperGlow = NSGradient(colors: [
    NSColor(calibratedWhite: 1, alpha: 0.14),
    NSColor(calibratedWhite: 1, alpha: 0.00),
])!
upperGlow.draw(in: NSBezierPath(ovalIn: upperGlowRect), relativeCenterPosition: NSPoint(x: 0, y: 0))

let lowerGlowRect = NSRect(x: 340, y: 60, width: 560, height: 360)
let lowerGlow = NSGradient(colors: [
    NSColor(calibratedRed: 0.82, green: 0.94, blue: 1.0, alpha: 0.16),
    NSColor(calibratedRed: 0.82, green: 0.94, blue: 1.0, alpha: 0.00),
])!
lowerGlow.draw(in: NSBezierPath(ovalIn: lowerGlowRect), relativeCenterPosition: NSPoint(x: 0, y: 0))

let topSheen = NSGradient(colors: [
    NSColor(calibratedWhite: 1, alpha: 0.16),
    NSColor(calibratedWhite: 1, alpha: 0.03),
    NSColor(calibratedWhite: 1, alpha: 0.00),
])!
topSheen.draw(in: NSBezierPath(rect: NSRect(x: 0, y: 610, width: 1024, height: 320)), angle: 90)
context.restoreGState()

NSColor(calibratedWhite: 1, alpha: 0.15).setStroke()
iconPath.lineWidth = 2
iconPath.stroke()

let panelRect = NSRect(x: 168, y: 206, width: 472, height: 566)
let panelPath = NSBezierPath(roundedRect: panelRect, xRadius: 124, yRadius: 124)

context.saveGState()
drawShadow(NSColor(calibratedWhite: 0, alpha: 0.12), blur: 20, offset: NSSize(width: 0, height: -8))
let panelGradient = NSGradient(colors: [
    NSColor(calibratedWhite: 1, alpha: 0.22),
    NSColor(calibratedRed: 0.93, green: 0.98, blue: 1.0, alpha: 0.08),
])!
panelGradient.draw(in: panelPath, angle: 90)
context.restoreGState()

NSColor(calibratedWhite: 1, alpha: 0.26).setStroke()
panelPath.lineWidth = 2
panelPath.stroke()

context.saveGState()
panelPath.addClip()
let reflection = NSGradient(colors: [
    NSColor(calibratedWhite: 1, alpha: 0.18),
    NSColor(calibratedWhite: 1, alpha: 0.00),
])!
reflection.draw(in: NSBezierPath(rect: NSRect(x: 186, y: 522, width: 420, height: 180)), angle: 90)
context.restoreGState()

let symbolColor = NSColor(calibratedWhite: 0.985, alpha: 1)
symbolColor.setFill()
NSBezierPath(ovalIn: NSRect(x: 357, y: 613, width: 96, height: 96)).fill()

let figure = NSBezierPath()
figure.lineWidth = 34
figure.lineCapStyle = .round
figure.lineJoinStyle = .round
figure.move(to: NSPoint(x: 405, y: 595))
figure.line(to: NSPoint(x: 405, y: 456))
figure.move(to: NSPoint(x: 405, y: 545))
figure.line(to: NSPoint(x: 324, y: 495))
figure.move(to: NSPoint(x: 405, y: 531))
figure.line(to: NSPoint(x: 496, y: 556))
figure.move(to: NSPoint(x: 405, y: 456))
figure.line(to: NSPoint(x: 334, y: 332))
figure.move(to: NSPoint(x: 405, y: 456))
figure.line(to: NSPoint(x: 478, y: 376))
figure.line(to: NSPoint(x: 556, y: 422))
symbolColor.setStroke()
figure.stroke()

let badgeRect = NSRect(x: 604, y: 150, width: 252, height: 252)
let badgePath = NSBezierPath(ovalIn: badgeRect)

context.saveGState()
drawShadow(NSColor(calibratedWhite: 0, alpha: 0.14), blur: 18, offset: NSSize(width: 0, height: -8))
let badgeGradient = NSGradient(colors: [
    NSColor(calibratedWhite: 1, alpha: 0.30),
    NSColor(calibratedRed: 0.90, green: 0.97, blue: 1.0, alpha: 0.16),
])!
badgeGradient.draw(in: badgePath, angle: 90)
context.restoreGState()

NSColor(calibratedWhite: 1, alpha: 0.32).setStroke()
badgePath.lineWidth = 2
badgePath.stroke()

let ringRect = badgeRect.insetBy(dx: 48, dy: 48)
let ringPath = NSBezierPath(ovalIn: ringRect)
ringPath.lineWidth = 18
symbolColor.setStroke()
ringPath.stroke()

let center = NSPoint(x: badgeRect.midX, y: badgeRect.midY)
let minuteHand = NSBezierPath()
minuteHand.lineWidth = 16
minuteHand.lineCapStyle = .round
minuteHand.move(to: center)
minuteHand.line(to: NSPoint(x: center.x, y: center.y + 56))
symbolColor.setStroke()
minuteHand.stroke()

let hourHand = NSBezierPath()
hourHand.lineWidth = 16
hourHand.lineCapStyle = .round
hourHand.move(to: center)
hourHand.line(to: NSPoint(x: center.x + 40, y: center.y - 24))
symbolColor.setStroke()
hourHand.stroke()

symbolColor.setFill()
NSBezierPath(ovalIn: NSRect(x: center.x - 10, y: center.y - 10, width: 20, height: 20)).fill()

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Unable to encode PNG.\n", stderr)
    exit(1)
}

try pngData.write(to: outputURL)
