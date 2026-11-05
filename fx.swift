// Screen-bending overlays for Raycast. Build: swiftc -O fx.swift -o fx
// Usage: fx quake | glitch | heatwave | dissolve | blackhole | gravity | tornado | flock | matrix [seconds]
//        fx countdown [message] [seconds]
// Every mode but tornado, flock, matrix and countdown starts from a screenshot, so the app running it needs Screen Recording.
import AppKit
import ScreenCaptureKit

let lengths: [String: CGFloat] = ["quake": 4, "glitch": 3, "heatwave": 5, "dissolve": 5,
                                  "blackhole": 5, "gravity": 4.8, "tornado": 6, "flock": 7, "matrix": 6, "countdown": 4.5]
let args = CommandLine.arguments.dropFirst()
guard let mode = args.first(where: { lengths[$0] != nil }) else {
    print("usage: fx \(lengths.keys.sorted().joined(separator: " | ")) [seconds]")
    exit(1)
}
let duration = args.compactMap(Double.init).first.map { CGFloat($0) } ?? lengths[mode]!
// Each effect is timed for its default length; a custom length stretches the whole timeline.
let stretch = lengths[mode]! / duration
// Countdown shows any other argument after the 1.
let message = args.first { lengths[$0] == nil && Double($0) == nil } ?? "Go!"
let needsSnap = !["tornado", "flock", "matrix", "countdown"].contains(mode)
if needsSnap && !CGPreflightScreenCaptureAccess() {
    CGRequestScreenCaptureAccess()
    exit(1)
}

let rgb = CGColorSpaceCreateDeviceRGB()
func rnd(_ a: CGFloat, _ b: CGFloat) -> CGFloat { .random(in: a...b) }
func clamp01(_ x: CGFloat) -> CGFloat { max(0, min(1, x)) }
func ease(_ x: CGFloat) -> CGFloat { x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2 }
func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
}
func bitmap(_ w: Int, _ h: Int) -> CGContext {
    CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
              space: rgb, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}

extension NSScreen {
    var displayID: CGDirectDisplayID { (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as! NSNumber).uint32Value }
}

func snapshots() async throws -> [CGDirectDisplayID: CGImage] {
    var out: [CGDirectDisplayID: CGImage] = [:]
    for d in try await SCShareableContent.current.displays {
        let scale = NSScreen.screens.first { $0.displayID == d.displayID }?.backingScaleFactor ?? 2
        let config = SCStreamConfiguration()
        config.width = Int(CGFloat(d.width) * scale)
        config.height = Int(CGFloat(d.height) * scale)
        config.showsCursor = false
        let filter = SCContentFilter(display: d, excludingWindows: [])
        out[d.displayID] = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config) as CGImage
    }
    return out
}

// Red-only and cyan-only copies of the screenshot, for the glitch's channel split.
func channels(_ img: CGImage) -> (CGImage, CGImage) {
    let w = img.width, h = img.height
    let src = bitmap(w, h), red = bitmap(w, h), cyan = bitmap(w, h)
    src.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
    let s = src.data!.assumingMemoryBound(to: UInt8.self)
    let r = red.data!.assumingMemoryBound(to: UInt8.self), c = cyan.data!.assumingMemoryBound(to: UInt8.self)
    for i in stride(from: 0, to: w * h * 4, by: 4) {
        r[i] = s[i]; r[i + 3] = 255
        c[i + 1] = s[i + 1]; c[i + 2] = s[i + 2]; c[i + 3] = 255
    }
    return (red.makeImage()!, cyan.makeImage()!)
}

// The stage is geometry-flipped, so everything below uses top-left, y-down coordinates like the previews.
struct Stage {
    let root: CALayer
    let size: CGSize
    let snap: CGImage?
    let mouse: CGPoint

    var full: CGRect { CGRect(origin: .zero, size: size) }

    func add<L: CALayer>(_ l: L) -> L { root.addSublayer(l); return l }

    func fill(_ c: CGColor, _ r: CGRect? = nil) -> CALayer {
        let l = add(CALayer())
        l.frame = r ?? full
        l.backgroundColor = c
        return l
    }

    // A layer showing the part of `img` that sits under `r` on screen.
    func piece(_ r: CGRect, _ img: CGImage? = nil) -> CALayer {
        let l = add(CALayer())
        l.contents = img ?? snap
        cut(l, r)
        return l
    }

    func cut(_ l: CALayer, _ r: CGRect) {
        l.frame = r
        l.contentsRect = CGRect(x: r.minX / size.width, y: r.minY / size.height,
                                width: r.width / size.width, height: r.height / size.height)
    }

    func tiles(_ t: CGFloat) -> [CGRect] {
        stride(from: 0, to: size.height, by: t).flatMap { y in
            stride(from: 0, to: size.width, by: t).map { x in CGRect(x: x, y: y, width: t, height: t) }
        }
    }
}

typealias Step = (_ t: CGFloat, _ dt: CGFloat) -> Void

func quake(_ s: Stage) -> Step {
    _ = s.fill(color(11, 13, 18))
    let img = s.piece(s.full)
    let (W, H) = (s.size.width, s.size.height)
    return { t, _ in
        let amp = 22 * min(1, t / 0.3) * max(0, 1 - t / 3.6)
        img.position = CGPoint(x: W / 2 + sin(t * 47) * amp + rnd(-1, 1) * amp * 0.4,
                               y: H / 2 + cos(t * 39) * amp * 0.6 + rnd(-1, 1) * amp * 0.3)
        img.setAffineTransform(CGAffineTransform(rotationAngle: sin(t * 31) * amp * 0.0008))
    }
}

func glitch(_ s: Stage) -> Step {
    _ = s.fill(color(0, 0, 0))
    let base = s.piece(s.full)
    let (redImg, cyanImg) = channels(s.snap!)
    let red = s.piece(s.full, redImg), cyan = s.piece(s.full, cyanImg)
    // The two copies hold disjoint channels, so screen-blending them rebuilds the picture.
    cyan.compositingFilter = CIFilter(name: "CIScreenBlendMode")
    let slices = (0..<7).map { _ in s.piece(s.full) }
    let bar = s.fill(color(255, 0, 90, 0.2))
    let (W, H) = (s.size.width, s.size.height)
    return { t, _ in
        let torn = sin(t * 9) + sin(t * 23) >= 0.4
        base.isHidden = torn
        ([red, cyan] + slices).forEach { $0.isHidden = !torn }
        bar.isHidden = !torn || CGFloat.random(in: 0...1) >= 0.35
        guard torn else { return }
        let off = rnd(4, 16)
        red.position.x = W / 2 + off
        cyan.position.x = W / 2 - off
        for l in slices {
            let y = rnd(0, H), h = rnd(4, 60)
            s.cut(l, CGRect(x: 0, y: y, width: W, height: h))
            l.position.x += rnd(-60, 60)
        }
        bar.frame = CGRect(x: 0, y: rnd(0, H), width: W, height: rnd(2, 30))
        bar.backgroundColor = Bool.random() ? color(255, 0, 90, 0.2) : color(0, 255, 220, 0.2)
    }
}

func heatwave(_ s: Stage) -> Step {
    _ = s.piece(s.full)
    let strips = stride(from: 0, to: s.size.height, by: 3).map { y in
        (y, s.piece(CGRect(x: 0, y: y, width: s.size.width, height: 3)))
    }
    _ = s.fill(color(255, 150, 60, 0.07))
    let W = s.size.width
    return { t, _ in
        let amp = min(1, t / 1.2) * 5
        for (y, l) in strips {
            l.position.x = W / 2 + sin(y * 0.045 + t * 7) * amp + sin(y * 0.013 - t * 3) * amp * 0.6
        }
    }
}

func dissolve(_ s: Stage) -> Step {
    _ = s.fill(color(11, 13, 18))
    let T: CGFloat = 20, W = s.size.width
    let bits = s.tiles(T).map { r in
        (r, s.piece(r), d: r.minX / W * 0.9 + rnd(0, 0.25), vx: rnd(160, 520), vy: rnd(-320, -40), w: rnd(0, 6.28))
    }
    return { t, _ in
        for p in bits {
            let f = ease(clamp01((t - 0.2 - p.d) / 1.1)) - ease(clamp01((t - 2.6 - p.d * 0.8) / 1.1))
            let sz = T * (1 - max(0, f) * 0.6)
            p.1.bounds.size = CGSize(width: sz, height: sz)
            p.1.opacity = Float(1 - max(0, f) * 0.8)
            p.1.position = f <= 0 ? CGPoint(x: p.0.midX, y: p.0.midY)
                : CGPoint(x: p.0.minX + p.vx * f * 1.6 + sin(f * 4 + p.w) * 24 * f + sz / 2,
                          y: p.0.minY + p.vy * f * 1.6 + sz / 2)
        }
    }
}

func blackhole(_ s: Stage) -> Step {
    _ = s.fill(color(5, 6, 10))
    let T: CGFloat = 20, c = s.mouse, reach = hypot(s.size.width, s.size.height)
    let bits = s.tiles(T).map { r in
        let dx = r.midX - c.x, dy = r.midY - c.y
        return (layer: s.piece(r), r: hypot(dx, dy), a: atan2(dy, dx))
    }
    let glow = s.add(CAGradientLayer())
    glow.type = .radial
    glow.startPoint = CGPoint(x: 0.5, y: 0.5)
    glow.endPoint = CGPoint(x: 1, y: 1)
    glow.colors = [color(0, 0, 0), color(0, 0, 0), color(255, 180, 100, 0.9), color(160, 80, 255, 0.45), color(120, 60, 255, 0)]
    glow.locations = [0, 0.6, 0.68, 0.8, 1]
    glow.position = c
    return { t, _ in
        let pull = ease(min(1, t / 3.4))
        for p in bits {
            let k = clamp01(pull * 2 - p.r / reach)
            p.layer.isHidden = k >= 1
            let e = ease(k), r = p.r * (1 - e), a = p.a + e * 4 + k * 2 / (r / 80 + 1), sz = T * (1 - k * 0.9)
            p.layer.position = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
            p.layer.bounds.size = CGSize(width: sz, height: sz)
        }
        let R = (14 + pull * 80) * 1.6
        glow.bounds = CGRect(x: 0, y: 0, width: R * 2, height: R * 2)
    }
}

func gravity(_ s: Stage) -> Step {
    _ = s.fill(color(11, 13, 18))
    let H = s.size.height, T = ceil(max(s.size.width, H) / 22)
    let bits = s.tiles(T).map { r in
        (r, s.piece(r), delay: 0.2 + rnd(0, 1.1) + (H - r.minY) / H * 0.4, vx: rnd(-50, 50), vr: rnd(-2.5, 2.5))
    }
    return { t, _ in
        for p in bits {
            let u = max(0, t - p.delay), y = p.0.minY + 900 * u * u
            p.1.isHidden = y > H + T
            p.1.position = CGPoint(x: p.0.midX + p.vx * u, y: y + T / 2)
            p.1.setAffineTransform(CGAffineTransform(rotationAngle: p.vr * u))
        }
    }
}

func tornado(_ s: Stage) -> Step {
    _ = s.fill(color(58, 62, 70, 0.42))
    struct Bit { let layer: CALayer; var h, a: CGFloat; let speed, size: CGFloat }
    var bits = (0..<1000).map { _ in
        Bit(layer: s.fill(color(125, 128, 134)), h: rnd(0, 1), a: rnd(0, 6.28), speed: rnd(0.6, 1.4), size: rnd(1, 3.5))
    }
    let (W, H) = (s.size.width, s.size.height)
    return { t, dt in
        let grow = min(1, t / 1.5), spread = max(0, (t - 4.6) / 1.4), cx = W / 2 + sin(t * 0.9) * W * 0.12
        for i in bits.indices {
            bits[i].h += dt * 0.12 * bits[i].speed
            if bits[i].h > 1 { bits[i].h = 0 }
            bits[i].a += dt * (6 / (0.4 + bits[i].h)) * bits[i].speed
            let p = bits[i]
            let rad = (14 + pow(p.h, 1.7) * min(W, H) * 0.34) * grow * (1 + spread * 2.5)
            let depth = (sin(p.a) + 1) / 2, sz = p.size * (0.6 + depth)
            p.layer.position = CGPoint(x: cx + sin(t * 1.3 + p.h * 2) * 40 * p.h + cos(p.a) * rad,
                                       y: H - p.h * H * 0.92 + sin(p.a) * rad * 0.12)
            p.layer.bounds.size = CGSize(width: sz, height: sz)
            p.layer.opacity = Float((0.35 + depth * 0.55) * (1 - spread))
        }
    }
}

// Boids: steer toward neighbours' centre and heading, away from crowding, and after a target crossing the screen.
func flock(_ s: Stage) -> Step {
    _ = s.fill(color(250, 170, 120, 0.22))
    let (W, H) = (s.size.width, s.size.height)
    let wing = CGMutablePath()
    wing.addLines(between: [CGPoint(x: 7, y: 0), CGPoint(x: -6, y: -6), CGPoint(x: -3, y: 0), CGPoint(x: -6, y: 6)])
    struct Bird { let layer: CAShapeLayer; var x, y, vx, vy: CGFloat }
    var birds = (0..<180).map { _ in
        let l = s.add(CAShapeLayer())
        l.path = wing
        l.fillColor = color(25, 22, 30, 0.85)
        return Bird(layer: l, x: rnd(-W * 0.4, -40), y: rnd(H * 0.2, H * 0.6), vx: rnd(120, 180), vy: rnd(-20, 20))
    }
    return { t, dt in
        let tx = -W * 0.2 + t / 7 * W * 1.6, ty = H * 0.35 + sin(t * 0.9) * H * 0.18
        for i in birds.indices {
            var a = birds[i]
            var n: CGFloat = 0, cx: CGFloat = 0, cy: CGFloat = 0, ax: CGFloat = 0, ay: CGFloat = 0, sx: CGFloat = 0, sy: CGFloat = 0
            for (j, o) in birds.enumerated() where j != i {
                let dx = o.x - a.x, dy = o.y - a.y, d2 = dx * dx + dy * dy
                guard d2 < 3600 else { continue }
                n += 1; cx += o.x; cy += o.y; ax += o.vx; ay += o.vy
                if d2 < 300 { sx -= dx; sy -= dy }
            }
            if n > 0 {
                a.vx += ((cx / n - a.x) * 0.8 + (ax / n - a.vx) * 1.5 + sx * 6) * dt
                a.vy += ((cy / n - a.y) * 0.8 + (ay / n - a.vy) * 1.5 + sy * 6) * dt
            }
            a.vx += (tx - a.x) * 0.25 * dt
            a.vy += (ty - a.y) * 0.25 * dt
            let sp = hypot(a.vx, a.vy), lim = min(260, max(120, sp)) / sp
            a.vx *= lim; a.vy *= lim
            a.x += a.vx * dt; a.y += a.vy * dt
            birds[i] = a
            a.layer.position = CGPoint(x: a.x, y: a.y)
            let flap = 0.55 + 0.45 * sin(t * 18 + CGFloat(i))
            a.layer.setAffineTransform(CGAffineTransform(rotationAngle: atan2(a.vy, a.vx)).scaledBy(x: 1, y: flap))
        }
    }
}

// One glyph drawn at 2x into a 16pt cell.
func glyph(_ ch: Character, _ c: NSColor) -> CGImage {
    let ctx = bitmap(32, 32)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    let text = NSAttributedString(string: String(ch), attributes: [
        .font: NSFont.monospacedSystemFont(ofSize: 28, weight: .medium), .foregroundColor: c])
    let size = text.size()
    text.draw(at: NSPoint(x: (32 - size.width) / 2, y: (32 - size.height) / 2))
    NSGraphicsContext.restoreGraphicsState()
    return ctx.makeImage()!
}

func matrix(_ s: Stage) -> Step {
    _ = s.fill(color(0, 8, 3, 0.82))
    let chars = Array("アカサタナハマヤラワ0123456789ABCDEF")
    let green = chars.map { glyph($0, NSColor(red: 0.2, green: 0.94, blue: 0.43, alpha: 1)) }
    let white = chars.map { glyph($0, NSColor(red: 0.85, green: 1, blue: 0.88, alpha: 1)) }
    let H = s.size.height
    // Each column is a bright head and a 17-glyph tail that fades out behind it.
    struct Column { var y: CGFloat; let speed: CGFloat; let cells: [CALayer] }
    var cols = (0..<Int(ceil(s.size.width / 16))).map { i in
        Column(y: rnd(-H, 0), speed: rnd(140, 320), cells: (0..<18).map { k in
            let l = s.add(CALayer())
            l.bounds = CGRect(x: 0, y: 0, width: 16, height: 16)
            l.position.x = CGFloat(i) * 16 + 8
            l.opacity = Float(1 - CGFloat(k) / 18)
            l.contents = (k == 0 ? white : green).randomElement()!
            return l
        })
    }
    return { _, dt in
        for i in cols.indices {
            cols[i].y += cols[i].speed * dt
            if cols[i].y - 300 > H { cols[i].y = rnd(-200, 0) }
            for (k, l) in cols[i].cells.enumerated() {
                l.position.y = cols[i].y - CGFloat(k) * 16
                if CGFloat.random(in: 0...1) < 0.08 { l.contents = (k == 0 ? white : green).randomElement()! }
            }
        }
    }
}

// Big 3, 2, 1, each punching in and fading, then the message.
func countdown(_ s: Stage) -> Step {
    _ = s.fill(color(0, 0, 0, 0.35))
    let (W, H) = (s.size.width, s.size.height)
    let label = s.add(CATextLayer())
    label.contentsScale = 2
    label.alignmentMode = .center
    label.foregroundColor = color(255, 255, 255)
    label.font = NSFont.systemFont(ofSize: 0, weight: .heavy)
    label.position = CGPoint(x: W / 2, y: H / 2)
    return { t, _ in
        let i = min(3, Int(t)), u = t - CGFloat(i)
        // Drawn at the largest size it reaches, then scaled down, so the punch-in stays sharp.
        let size = (i < 3 ? min(W, H) * 0.42 : min(W / 8, 90)) * 1.5
        label.string = i < 3 ? "\(3 - i)" : message
        label.fontSize = size
        label.bounds = CGRect(x: 0, y: 0, width: W, height: size * 1.25)
        label.opacity = Float(i < 3 ? 1 - clamp01((u - 0.65) / 0.35) : 1)
        let sc = (1.5 - 0.5 * ease(min(1, u / 0.25))) / 1.5
        label.setAffineTransform(CGAffineTransform(scaleX: sc, y: sc))
    }
}

let effects: [String: (Stage) -> Step] = ["quake": quake, "glitch": glitch, "heatwave": heatwave, "dissolve": dissolve,
                                          "blackhole": blackhole, "gravity": gravity, "tornado": tornado, "flock": flock,
                                          "matrix": matrix, "countdown": countdown]

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

// Shoot every screen before any overlay is up, so the overlays never photograph themselves.
let snaps = needsSnap ? try await snapshots() : [:]
let mouse = NSEvent.mouseLocation

var windows: [NSWindow] = []
var stages: [CALayer] = []
var steps: [Step] = []
for screen in NSScreen.screens {
    let frame = screen.frame
    let window = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
    window.isOpaque = false
    window.backgroundColor = .clear
    window.hasShadow = false
    window.ignoresMouseEvents = true
    window.level = .screenSaver
    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
    let view = NSView(frame: NSRect(origin: .zero, size: frame.size))
    view.wantsLayer = true
    view.layerUsesCoreImageFilters = true
    window.contentView = view
    window.setFrame(frame, display: false)

    let root = CALayer()
    root.frame = view.bounds
    root.isGeometryFlipped = true
    root.opacity = 0
    view.layer!.addSublayer(root)
    // The black hole opens at the cursor; on the other screens it opens in the middle.
    let local = frame.contains(mouse) ? CGPoint(x: mouse.x - frame.minX, y: frame.maxY - mouse.y)
        : CGPoint(x: frame.width / 2, y: frame.height / 2)
    steps.append(effects[mode]!(Stage(root: root, size: frame.size, snap: snaps[screen.displayID], mouse: local)))
    stages.append(root)
    window.orderFrontRegardless()
    windows.append(window)
}

let start = CACurrentMediaTime()
var last = start
Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { _ in
    let now = CACurrentMediaTime(), e = CGFloat(now - start), dt = CGFloat(min(0.05, now - last))
    last = now
    if e >= duration { exit(0) }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    let fade = Float(min(1, e / 0.35, (duration - e) / 0.8))
    stages.forEach { $0.opacity = fade }
    steps.forEach { $0(e * stretch, dt * stretch) }
    CATransaction.commit()
}

app.run()
