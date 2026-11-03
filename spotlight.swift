// Cursor spotlight for Raycast: dims every screen except a soft circle around the mouse.
// Build: swiftc -O spotlight.swift -o spotlight. Runs until killed; spotlight.sh toggles it.
import AppKit
import QuartzCore

let radius: CGFloat = 180
let dim = CGColor(red: 0.02, green: 0.03, blue: 0.06, alpha: 0.72)
let clear = CGColor(red: 0, green: 0, blue: 0, alpha: 0)

struct Light {
    let frame: CGRect
    let shade: CALayer
    let spot: CAGradientLayer
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

var windows: [NSWindow] = []
var lights: [Light] = []
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
    window.contentView = view
    window.setFrame(frame, display: false)

    let shade = CALayer()
    shade.frame = CGRect(origin: .zero, size: frame.size)
    view.layer!.addSublayer(shade)

    // A radial gradient big enough that its dim ring reaches every corner from any cursor position.
    let reach = hypot(frame.width, frame.height)
    let spot = CAGradientLayer()
    spot.type = .radial
    spot.bounds = CGRect(x: 0, y: 0, width: reach * 2, height: reach * 2)
    spot.startPoint = CGPoint(x: 0.5, y: 0.5)
    spot.endPoint = CGPoint(x: 1, y: 1)
    spot.colors = [clear, clear, dim, dim]
    spot.locations = [0, NSNumber(value: Double(radius * 0.4 / reach)), NSNumber(value: Double(radius / reach)), 1]
    shade.addSublayer(spot)

    let fade = CABasicAnimation(keyPath: "opacity")
    fade.fromValue = 0
    fade.duration = 0.4
    shade.add(fade, forKey: "in")

    window.orderFrontRegardless()
    windows.append(window)
    lights.append(Light(frame: frame, shade: shade, spot: spot))
}

// Screens without the cursor are fully dimmed; the one with it gets the hole.
func follow() {
    let mouse = NSEvent.mouseLocation
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    for l in lights {
        let inside = l.frame.contains(mouse)
        l.spot.isHidden = !inside
        l.shade.backgroundColor = inside ? nil : dim
        if inside { l.spot.position = CGPoint(x: mouse.x - l.frame.minX, y: mouse.y - l.frame.minY) }
    }
    CATransaction.commit()
}
follow()
Timer.scheduledTimer(withTimeInterval: 1.0 / 120, repeats: true) { _ in follow() }

// Fade out on kill instead of vanishing.
signal(SIGTERM, SIG_IGN)
let term = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
term.setEventHandler {
    for l in lights {
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.toValue = 0
        fade.duration = 0.4
        fade.fillMode = .forwards
        fade.isRemovedOnCompletion = false
        l.shade.add(fade, forKey: "out")
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { exit(0) }
}
term.resume()

app.run()
