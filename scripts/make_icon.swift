// 生成 app 图标：swift scripts/make_icon.swift <输出.png>
import AppKit

let size = 1024
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(deviceRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

// macOS 图标规范：1024 画布内 824 的圆角方块
let plate = NSRect(x: 100, y: 100, width: 824, height: 824)
let platePath = NSBezierPath(roundedRect: plate, xRadius: 185, yRadius: 185)
NSGradient(starting: color(0x0D0F1E), ending: color(0x2E3358))!.draw(in: platePath, angle: 90)

let center = NSPoint(x: 512, y: 512)
NSGraphicsContext.saveGraphicsState()
platePath.addClip()
NSGradient(colors: [color(0xFFB02E, 0.55), color(0xFF8A1F, 0.18), color(0xFF8A1F, 0)])!
    .draw(fromCenter: center, radius: 0, toCenter: center, radius: 400, options: [])
NSGraphicsContext.restoreGraphicsState()

// 光芒
color(0xFFC548).setStroke()
for i in 0..<8 {
    let angle = CGFloat(i) * .pi / 4
    let ray = NSBezierPath()
    ray.lineWidth = 46
    ray.lineCapStyle = .round
    ray.move(to: NSPoint(x: center.x + cos(angle) * 222, y: center.y + sin(angle) * 222))
    ray.line(to: NSPoint(x: center.x + cos(angle) * 292, y: center.y + sin(angle) * 292))
    ray.stroke()
}

// 日面
let disc = NSRect(x: center.x - 150, y: center.y - 150, width: 300, height: 300)
NSGradient(starting: color(0xFF9A1F), ending: color(0xFFE88A))!
    .draw(in: NSBezierPath(ovalIn: disc), angle: 90)

NSGraphicsContext.current?.flushGraphics()
try! rep.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
