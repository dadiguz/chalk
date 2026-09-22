#!/usr/bin/env swift
// Genera el ícono de la app (1024×1024): "CHALK" en Real Chalk sobre pizarrón.
// Requiere la fuente en Chalk/Resources/Fonts/ (ignorada por git por su licencia).
// Uso: swift Scripts/make-icon.swift
import AppKit
import CoreText

let size = 1024.0
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let fontURL = root.appending(path: "Chalk/Resources/Fonts/real-chalk.regular.otf")
CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
let out = root.appending(path: "Chalk/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png").path

struct Seeded: RandomNumberGenerator { var s: UInt64; mutating func next() -> UInt64 { s = s &* 6364136223846793005 &+ 1442695040888963407; return s } }
var r = Seeded(s: 42)
func rnd(_ a: Double, _ b: Double) -> Double { Double.random(in: a...b, using: &r) }

let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!

// Pizarrón: #0A0E15 con viñeta suave hacia #212631 en el centro.
let bg = CGGradient(colorsSpace: cs, colors: [CGColor(red: 0.15, green: 0.17, blue: 0.21, alpha: 1), CGColor(red: 0.039, green: 0.055, blue: 0.082, alpha: 1)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(bg, startCenter: CGPoint(x: size/2, y: size*0.55), startRadius: 0, endCenter: CGPoint(x: size/2, y: size/2), endRadius: size*0.78, options: [.drawsAfterEndLocation])

// Borrones de gis: óvalos blancos muy tenues y difusos.
for _ in 0..<14 {
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 60, color: CGColor(gray: 1, alpha: 0.05))
    ctx.setFillColor(CGColor(gray: 1, alpha: 0.018))
    let w = rnd(220, 520), h = rnd(40, 110)
    ctx.translateBy(x: rnd(0, size), y: rnd(0, size)); ctx.rotate(by: rnd(-0.5, 0.5))
    ctx.fillEllipse(in: CGRect(x: -w/2, y: -h/2, width: w, height: h))
    ctx.restoreGState()
}
// Polvo fino.
for _ in 0..<2600 {
    ctx.setFillColor(CGColor(gray: 1, alpha: rnd(0.02, 0.09)))
    let d = rnd(0.8, 2.4)
    ctx.fillEllipse(in: CGRect(x: rnd(0, size), y: rnd(0, size), width: d, height: d))
}

// Texto.
let fontSize = 250.0
let font = CTFontCreateWithName("RealChalk" as CFString, fontSize, nil)
let attr = NSAttributedString(string: "CHALK", attributes: [.init(kCTFontAttributeName as String): font, .init(kCTForegroundColorAttributeName as String): CGColor(gray: 0.97, alpha: 1)])
let line = CTLineCreateWithAttributedString(attr)
let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
let scale = min(1, (size * 0.82) / bounds.width)
let textY = size / 2
ctx.saveGState()
ctx.translateBy(x: size/2, y: textY)
ctx.scaleBy(x: scale, y: scale)
ctx.rotate(by: -0.035)
ctx.setShadow(offset: .zero, blur: 18, color: CGColor(gray: 1, alpha: 0.28))
ctx.textPosition = CGPoint(x: -bounds.midX, y: -bounds.midY)
CTLineDraw(line, ctx)
ctx.restoreGState()

let image = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: image)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
