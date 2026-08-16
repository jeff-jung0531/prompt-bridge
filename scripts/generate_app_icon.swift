#!/usr/bin/env swift
import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("assets", isDirectory: true)
let iconset = assets.appendingPathComponent("AppIcon.iconset", isDirectory: true)

try? FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

struct IconSpec {
    let filename: String
    let pixels: Int
}

let specs = [
    IconSpec(filename: "icon_16x16.png", pixels: 16),
    IconSpec(filename: "icon_16x16@2x.png", pixels: 32),
    IconSpec(filename: "icon_32x32.png", pixels: 32),
    IconSpec(filename: "icon_32x32@2x.png", pixels: 64),
    IconSpec(filename: "icon_128x128.png", pixels: 128),
    IconSpec(filename: "icon_128x128@2x.png", pixels: 256),
    IconSpec(filename: "icon_256x256.png", pixels: 256),
    IconSpec(filename: "icon_256x256@2x.png", pixels: 512),
    IconSpec(filename: "icon_512x512.png", pixels: 512),
    IconSpec(filename: "icon_512x512@2x.png", pixels: 1024),
]

func drawIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    let scale = CGFloat(size) / 1024.0
    let bounds = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    bounds.fill()

    let outer = NSBezierPath(roundedRect: bounds.insetBy(dx: 64 * scale, dy: 64 * scale),
                             xRadius: 210 * scale,
                             yRadius: 210 * scale)
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.05, green: 0.08, blue: 0.12, alpha: 1),
        NSColor(calibratedRed: 0.08, green: 0.13, blue: 0.19, alpha: 1),
        NSColor(calibratedRed: 0.01, green: 0.03, blue: 0.05, alpha: 1),
    ])!
    gradient.draw(in: outer, angle: 135)

    NSColor(calibratedRed: 0.38, green: 0.95, blue: 0.76, alpha: 0.95).setStroke()
    outer.lineWidth = 12 * scale
    outer.stroke()

    let panel = NSBezierPath(roundedRect: NSRect(x: 168 * scale,
                                                 y: 228 * scale,
                                                 width: 688 * scale,
                                                 height: 568 * scale),
                             xRadius: 74 * scale,
                             yRadius: 74 * scale)
    NSColor(calibratedRed: 0.96, green: 0.99, blue: 1.0, alpha: 0.10).setFill()
    panel.fill()
    NSColor(calibratedRed: 0.75, green: 0.91, blue: 1.0, alpha: 0.28).setStroke()
    panel.lineWidth = 7 * scale
    panel.stroke()

    let promptAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedSystemFont(ofSize: 230 * scale, weight: .bold),
        .foregroundColor: NSColor(calibratedRed: 0.39, green: 0.98, blue: 0.77, alpha: 1),
    ]
    NSString(string: "MD").draw(at: NSPoint(x: 222 * scale, y: 430 * scale), withAttributes: promptAttributes)

    let cursor = NSBezierPath(roundedRect: NSRect(x: 472 * scale,
                                                  y: 428 * scale,
                                                  width: 220 * scale,
                                                  height: 34 * scale),
                              xRadius: 17 * scale,
                              yRadius: 17 * scale)
    NSColor(calibratedRed: 0.39, green: 0.98, blue: 0.77, alpha: 1).setFill()
    cursor.fill()

    let globeRect = NSRect(x: 548 * scale,
                           y: 556 * scale,
                           width: 220 * scale,
                           height: 220 * scale)
    let globe = NSBezierPath(ovalIn: globeRect)
    NSColor(calibratedRed: 0.93, green: 0.98, blue: 1.0, alpha: 0.94).setFill()
    globe.fill()
    NSColor(calibratedRed: 0.04, green: 0.09, blue: 0.13, alpha: 0.95).setStroke()
    globe.lineWidth = 8 * scale
    globe.stroke()

    NSColor(calibratedRed: 0.04, green: 0.09, blue: 0.13, alpha: 0.55).setStroke()
    for offset in [-54.0, 0.0, 54.0] {
        let x = globeRect.midX + CGFloat(offset) * scale
        let meridian = NSBezierPath()
        meridian.move(to: NSPoint(x: x, y: globeRect.minY + 18 * scale))
        meridian.curve(to: NSPoint(x: x, y: globeRect.maxY - 18 * scale),
                       controlPoint1: NSPoint(x: x - 42 * scale, y: globeRect.midY - 54 * scale),
                       controlPoint2: NSPoint(x: x - 42 * scale, y: globeRect.midY + 54 * scale))
        meridian.lineWidth = 5 * scale
        meridian.stroke()
    }
    for offset in [-44.0, 0.0, 44.0] {
        let y = globeRect.midY + CGFloat(offset) * scale
        let parallel = NSBezierPath()
        parallel.move(to: NSPoint(x: globeRect.minX + 18 * scale, y: y))
        parallel.curve(to: NSPoint(x: globeRect.maxX - 18 * scale, y: y),
                       controlPoint1: NSPoint(x: globeRect.midX - 52 * scale, y: y + 20 * scale),
                       controlPoint2: NSPoint(x: globeRect.midX + 52 * scale, y: y + 20 * scale))
        parallel.lineWidth = 5 * scale
        parallel.stroke()
    }

    let langBadge = NSBezierPath(roundedRect: NSRect(x: 496 * scale,
                                                     y: 572 * scale,
                                                     width: 182 * scale,
                                                     height: 98 * scale),
                                 xRadius: 34 * scale,
                                 yRadius: 34 * scale)
    NSColor(calibratedRed: 0.39, green: 0.98, blue: 0.77, alpha: 0.94).setFill()
    langBadge.fill()

    let langAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 56 * scale, weight: .bold),
        .foregroundColor: NSColor(calibratedRed: 0.04, green: 0.09, blue: 0.13, alpha: 1),
    ]
    NSString(string: "FILE").draw(at: NSPoint(x: 522 * scale, y: 596 * scale), withAttributes: langAttributes)

    return image
}

func writePNG(_ image: NSImage, to url: URL, pixels: Int) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create PNG"])
    }
    try png.write(to: url)
}

for spec in specs {
    let image = drawIcon(size: spec.pixels)
    try writePNG(image, to: iconset.appendingPathComponent(spec.filename), pixels: spec.pixels)
}

try writePNG(drawIcon(size: 1024), to: assets.appendingPathComponent("AppIconPreview.png"), pixels: 1024)
print("Generated iconset: \(iconset.path)")
