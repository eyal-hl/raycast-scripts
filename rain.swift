// Gloomy rain overlay for Raycast. Build: swiftc -O rain.swift -o rain
// Usage: rain [storm] [seconds]
import AppKit
import QuartzCore

let args = CommandLine.arguments.dropFirst()
let storm = args.contains("storm")
let duration = args.compactMap(Double.init).first ?? (storm ? 14 : 12)
let rgb = CGColorSpaceCreateDeviceRGB()

func bitmap(_ w: Int, _ h: Int) -> CGContext {
    CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
              space: rgb, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}

func grey(_ g: CGFloat, _ a: CGFloat) -> CGColor { CGColor(red: g, green: g, blue: g + 0.04, alpha: a) }

func dropImage() -> CGImage {
    let ctx = bitmap(3, 80)
    let grad = CGGradient(colorsSpace: rgb, colors: [CGColor(red: 0.7, green: 0.76, blue: 0.85, alpha: 0.8),
                                                     CGColor(red: 0.7, green: 0.76, blue: 0.85, alpha: 0)] as CFArray,
                          locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: .zero, end: CGPoint(x: 0, y: 80), options: [])
    return ctx.makeImage()!
}

// A band of soft grey puffs, solid at the top, lumpy at the bottom.
func cloudImage(width: Int, height: Int, shade: CGFloat) -> CGImage {
    let ctx = bitmap(width, height)
    let h = CGFloat(height)
    let top = CGGradient(colorsSpace: rgb, colors: [grey(shade, 0), grey(shade, 0.95)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(top, start: CGPoint(x: 0, y: h * 0.45), end: CGPoint(x: 0, y: h), options: [])
    for _ in 0..<(width / 35) {
        let g = shade + .random(in: -0.06...0.06)
        let r = CGFloat.random(in: h * 0.18...h * 0.42)
        let c = CGPoint(x: .random(in: 0...CGFloat(width)), y: .random(in: h * 0.3...h))
        let puff = CGGradient(colorsSpace: rgb, colors: [grey(g, 0.9), grey(g, 0.6), grey(g, 0)] as CFArray,
                              locations: [0, 0.55, 1])!
        ctx.drawRadialGradient(puff, startCenter: c, startRadius: 0, endCenter: c, endRadius: r, options: [])
    }
    return ctx.makeImage()!
}

func addClouds(_ root: CALayer, _ size: CGSize, shade: CGFloat, height: CGFloat, drift: CGFloat) {
    let layer = CALayer()
    let width = size.width * 1.4
    layer.contents = cloudImage(width: Int(width), height: Int(height), shade: shade)
    layer.bounds = CGRect(x: 0, y: 0, width: width, height: height)
    layer.position = CGPoint(x: size.width / 2, y: size.height - height * 0.35)
    root.addSublayer(layer)

    let fall = CABasicAnimation(keyPath: "position.y")
    fall.fromValue = size.height + height / 2
    fall.duration = 2.5
    fall.timingFunction = CAMediaTimingFunction(name: .easeOut)
    layer.add(fall, forKey: "fall")

    let sway = CABasicAnimation(keyPath: "position.x")
    sway.fromValue = size.width / 2 - drift
    sway.toValue = size.width / 2 + drift
    sway.duration = 25
    sway.autoreverses = true
    sway.repeatCount = .infinity
    layer.add(sway, forKey: "sway")
}

func flashLayer(_ root: CALayer, _ size: CGSize) -> CALayer {
    let layer = CALayer()
    layer.frame = CGRect(origin: .zero, size: size)
    layer.backgroundColor = CGColor(red: 0.85, green: 0.88, blue: 1, alpha: 1)
    layer.opacity = 0
    root.addSublayer(layer)
    return layer
}

func flicker(_ layer: CALayer, peak: Float) {
    let a = CAKeyframeAnimation(keyPath: "opacity")
    a.values = [0, peak, peak * 0.1, peak * 0.8, 0]
    a.keyTimes = [0, 0.06, 0.2, 0.3, 1]
    a.duration = 0.7
    layer.add(a, forKey: nil)
}

func strike(_ root: CALayer, _ flash: CALayer, _ size: CGSize) {
    let path = CGMutablePath()
    var p = CGPoint(x: .random(in: size.width * 0.15...size.width * 0.85), y: size.height - 120)
    path.move(to: p)
    let bottom = CGFloat.random(in: 0...size.height * 0.4)
    while p.y > bottom {
        p = CGPoint(x: p.x + .random(in: -45...45), y: p.y - .random(in: 25...70))
        path.addLine(to: p)
        if Int.random(in: 0..<6) == 0 {
            var b = p
            for _ in 0..<Int.random(in: 2...5) {
                b = CGPoint(x: b.x + .random(in: -60...60), y: b.y - .random(in: 20...50))
                path.addLine(to: b)
            }
            path.move(to: p)
        }
    }
    let bolt = CAShapeLayer()
    bolt.path = path
    bolt.strokeColor = CGColor(red: 0.95, green: 0.97, blue: 1, alpha: 1)
    bolt.fillColor = nil
    bolt.lineWidth = 2.5
    bolt.lineJoin = .miter
    bolt.shadowColor = CGColor(red: 0.6, green: 0.7, blue: 1, alpha: 1)
    bolt.shadowRadius = 12
    bolt.shadowOpacity = 1
    bolt.shadowOffset = .zero
    bolt.opacity = 0
    root.addSublayer(bolt)
    flicker(bolt, peak: 1)
    flicker(flash, peak: 0.35)
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { bolt.removeFromSuperlayer() }
}

final class Scene {
    let root: CALayer
    let size: CGSize
    let rain = CALayer()
    var flash: CALayer?

    init(root: CALayer, size: CGSize) {
        self.root = root
        self.size = size

        let gloom = CALayer()
        gloom.frame = CGRect(origin: .zero, size: size)
        gloom.backgroundColor = CGColor(red: 0.08, green: 0.1, blue: 0.14, alpha: 1)
        gloom.opacity = storm ? 0.45 : 0.3
        root.addSublayer(gloom)

        // One looping layer per drop; CAEmitterLayer only drew in the top-left of this overlay window.
        let drop = dropImage()
        for _ in 0..<(storm ? 700 : 400) {
            let d = CALayer()
            let s = CGFloat.random(in: 0.3...0.6)
            d.contents = drop
            d.bounds = CGRect(x: 0, y: 0, width: 3 * s, height: 80 * s)
            d.opacity = .random(in: 0.4...1)
            d.position = CGPoint(x: -100, y: -100)
            let x = CGFloat.random(in: 0...size.width)
            let fall = CABasicAnimation(keyPath: "position")
            fall.fromValue = CGPoint(x: x, y: size.height + 50)
            fall.toValue = CGPoint(x: x, y: -50)
            fall.duration = .random(in: 0.55...0.9)
            fall.timeOffset = .random(in: 0...fall.duration)
            fall.repeatCount = .infinity
            d.add(fall, forKey: "fall")
            rain.addSublayer(d)
        }
        root.addSublayer(rain)

        addClouds(root, size, shade: storm ? 0.22 : 0.38, height: size.height * 0.32, drift: 60)
        addClouds(root, size, shade: storm ? 0.3 : 0.48, height: size.height * 0.22, drift: -90)
        if storm { flash = flashLayer(root, size) }

        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0
        fade.duration = 1.5
        root.add(fade, forKey: "in")
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

var windows: [NSWindow] = []
var scenes: [Scene] = []
for screen in NSScreen.screens {
    let window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
    window.isOpaque = false
    window.backgroundColor = .clear
    window.hasShadow = false
    window.ignoresMouseEvents = true
    window.level = .screenSaver
    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
    let view = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
    view.wantsLayer = true
    window.contentView = view
    window.setFrame(screen.frame, display: false)
    scenes.append(Scene(root: view.layer!, size: screen.frame.size))
    window.orderFrontRegardless()
    windows.append(window)
}

func thunder() {
    for s in scenes { if let flash = s.flash { strike(s.root, flash, s.size) } }
    DispatchQueue.main.asyncAfter(deadline: .now() + .random(in: 2.5...5.5), execute: thunder)
}
if storm { DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: thunder) }

DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
    CATransaction.begin()
    CATransaction.setAnimationDuration(2)
    CATransaction.setCompletionBlock { exit(0) }
    scenes.forEach { $0.root.opacity = 0 }
    CATransaction.commit()
}

app.run()
