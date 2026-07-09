#!/usr/bin/env swift
//
// Draws the Chroma Sort app icon and writes every size the asset catalog
// needs. Run from anywhere:
//
//     swift apple/Scripts/MakeIcon.swift
//
// iOS marketing icons must have no alpha channel, so those are rendered into an
// opaque context. macOS icons are expected to be a rounded shape floating in a
// transparent margin, so those keep their alpha.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - Palette (mirrors index.html)

let bg0 = (r: 0.051, g: 0.055, b: 0.110) // #0d0e1c
let bg1 = (r: 0.082, g: 0.090, b: 0.169) // #15172b
// Three well-separated hues rather than three warm ones, so the mark reads as
// "chroma" and not as a traffic light.
let ballPink = (r: 1.000, g: 0.329, b: 0.439) // #ff5470
let ballTeal = (r: 0.125, g: 0.788, b: 0.592) // #20c997
let ballYellow = (r: 1.000, g: 0.882, b: 0.102) // #ffe11a

let space = CGColorSpace(name: CGColorSpace.sRGB)!

func rgb(_ c: (r: Double, g: Double, b: Double), _ a: Double = 1) -> CGColor {
    CGColor(colorSpace: space, components: [c.r, c.g, c.b, a])!
}

func gray(_ v: Double, _ a: Double) -> CGColor {
    CGColor(colorSpace: space, components: [v, v, v, a])!
}

// MARK: - Drawing (authored on a 1024pt canvas, scaled to any size)

/// - Parameter inset: fraction of the canvas left as transparent margin.
///   0 for iOS (the system masks it), ~0.10 for the macOS squircle.
func drawIcon(into ctx: CGContext, size: CGFloat, inset: CGFloat, rounded: Bool) {
    let s = size / 1024.0
    let margin = size * inset
    let plate = CGRect(x: margin, y: margin, width: size - 2 * margin, height: size - 2 * margin)

    ctx.saveGState()
    if rounded {
        // Apple's icon grid: corner radius ≈ 22.37% of the icon's width.
        let path = CGPath(
            roundedRect: plate, cornerWidth: plate.width * 0.2237, cornerHeight: plate.width * 0.2237,
            transform: nil
        )
        ctx.addPath(path)
        ctx.clip()
    }

    // Backdrop: the same diagonal wash the page uses.
    let backdrop = CGGradient(
        colorsSpace: space,
        colors: [rgb(bg1), rgb(bg0)] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(
        backdrop,
        start: CGPoint(x: plate.minX, y: plate.maxY),
        end: CGPoint(x: plate.maxX, y: plate.minY),
        options: []
    )

    // Violet glow, top-right.
    let glow = CGGradient(
        colorsSpace: space,
        colors: [
            CGColor(colorSpace: space, components: [0.482, 0.380, 1.0, 0.42])!,
            CGColor(colorSpace: space, components: [0.482, 0.380, 1.0, 0.0])!,
        ] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawRadialGradient(
        glow,
        startCenter: CGPoint(x: 800 * s, y: 900 * s), startRadius: 0,
        endCenter: CGPoint(x: 800 * s, y: 900 * s), endRadius: 620 * s,
        options: []
    )

    // Teal glow, bottom-left.
    let teal = CGGradient(
        colorsSpace: space,
        colors: [
            CGColor(colorSpace: space, components: [0.0, 0.820, 0.698, 0.30])!,
            CGColor(colorSpace: space, components: [0.0, 0.820, 0.698, 0.0])!,
        ] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawRadialGradient(
        teal,
        startCenter: CGPoint(x: 150 * s, y: 120 * s), startRadius: 0,
        endCenter: CGPoint(x: 150 * s, y: 120 * s), endRadius: 560 * s,
        options: []
    )

    // The tube. CoreGraphics is y-up; the authored coordinates are y-down, so
    // flip them once here.
    let tube = CGRect(x: 382 * s, y: (1024 - 880) * s, width: 260 * s, height: 720 * s)
    let tubePath = CGPath(roundedRect: tube, cornerWidth: 130 * s, cornerHeight: 130 * s, transform: nil)

    ctx.addPath(tubePath)
    ctx.setFillColor(gray(1, 0.06))
    ctx.fillPath()

    // Balls, bottom to top.
    let balls: [(CGFloat, (r: Double, g: Double, b: Double))] = [
        (752, ballYellow),
        (532, ballTeal),
        (312, ballPink),
    ]
    ctx.saveGState()
    ctx.addPath(tubePath)
    ctx.clip()
    for (yDown, color) in balls {
        let center = CGPoint(x: 512 * s, y: (1024 - yDown) * s)
        let radius = 106 * s

        let sphere = CGGradient(
            colorsSpace: space,
            colors: [
                CGColor(colorSpace: space, components: [
                    min(1, color.r + 0.24), min(1, color.g + 0.24), min(1, color.b + 0.24), 1,
                ])!,
                rgb(color),
                CGColor(colorSpace: space, components: [color.r * 0.62, color.g * 0.62, color.b * 0.62, 1])!,
            ] as CFArray,
            locations: [0, 0.55, 1]
        )!
        ctx.saveGState()
        ctx.addEllipse(in: CGRect(
            x: center.x - radius, y: center.y - radius,
            width: radius * 2, height: radius * 2
        ))
        ctx.clip()
        let lit = CGPoint(x: center.x - radius * 0.32, y: center.y + radius * 0.34)
        ctx.drawRadialGradient(
            sphere,
            startCenter: lit, startRadius: 0,
            endCenter: center, endRadius: radius * 1.22,
            options: [.drawsAfterEndLocation]
        )

        // Specular highlight.
        let shine = CGGradient(
            colorsSpace: space,
            colors: [gray(1, 0.75), gray(1, 0)] as CFArray,
            locations: [0, 1]
        )!
        ctx.drawRadialGradient(
            shine,
            startCenter: lit, startRadius: 0,
            endCenter: lit, endRadius: radius * 0.52,
            options: []
        )
        ctx.restoreGState()
    }
    ctx.restoreGState()

    // Glass rim and a vertical shine down the left wall, drawn over the balls.
    ctx.addPath(tubePath)
    ctx.setStrokeColor(gray(1, 0.20))
    ctx.setLineWidth(7 * s)
    ctx.strokePath()

    ctx.saveGState()
    ctx.addPath(tubePath)
    ctx.clip()
    ctx.setFillColor(gray(1, 0.13))
    ctx.fill(CGRect(x: 410 * s, y: (1024 - 830) * s, width: 26 * s, height: 600 * s))
    ctx.restoreGState()

    ctx.restoreGState()
}

func makeImage(size: CGFloat, inset: CGFloat, rounded: Bool, opaque: Bool) -> CGImage {
    let pixels = Int(size)
    let ctx = CGContext(
        data: nil,
        width: pixels,
        height: pixels,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: space,
        // noneSkipLast => the written PNG carries no alpha channel at all.
        bitmapInfo: (opaque ? CGImageAlphaInfo.noneSkipLast : CGImageAlphaInfo.premultipliedLast).rawValue
    )!
    if opaque {
        ctx.setFillColor(rgb(bg0))
        ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
    }
    ctx.interpolationQuality = .high
    drawIcon(into: ctx, size: size, inset: inset, rounded: rounded)
    return ctx.makeImage()!
}

func write(_ image: CGImage, to url: URL) {
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        fatalError("cannot create \(url.path)")
    }
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("cannot write \(url.path)") }
}

// MARK: - Emit the asset catalog

let scriptDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let iconSet = scriptDir
    .deletingLastPathComponent()
    .appendingPathComponent("ChromaSort/Resources/Assets.xcassets/AppIcon.appiconset")
try! FileManager.default.createDirectory(at: iconSet, withIntermediateDirectories: true)

var images: [[String: String]] = []

// iOS: one 1024pt universal image, opaque, full-bleed (the system masks it).
write(makeImage(size: 1024, inset: 0, rounded: false, opaque: true), to: iconSet.appendingPathComponent("icon-ios-1024.png"))
images.append(["filename": "icon-ios-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"])

// macOS: the full ladder, rounded, with a transparent margin.
let macSizes: [(pt: Int, scale: Int)] = [
    (16, 1), (16, 2), (32, 1), (32, 2),
    (128, 1), (128, 2), (256, 1), (256, 2), (512, 1), (512, 2),
]
for (pt, scale) in macSizes {
    let px = pt * scale
    let name = "icon-mac-\(pt)x\(pt)@\(scale)x.png"
    write(makeImage(size: CGFloat(px), inset: 0.10, rounded: true, opaque: false), to: iconSet.appendingPathComponent(name))
    images.append([
        "filename": name, "idiom": "mac", "scale": "\(scale)x", "size": "\(pt)x\(pt)",
    ])
}

let contents: [String: Any] = [
    "images": images,
    "info": ["author": "xcode", "version": 1],
]
let json = try! JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try! json.write(to: iconSet.appendingPathComponent("Contents.json"))

print("wrote \(images.count) images to \(iconSet.path)")
