import Cocoa

final class MascotView: NSView {
    enum Look: CaseIterable {
        case topLeft, topRight, bottomLeft, bottomRight

        var offset: (CGFloat, CGFloat) {
            switch self {
            case .topLeft: return (0, 0)
            case .topRight: return (1, 0)
            case .bottomLeft: return (0, 1)
            case .bottomRight: return (1, 1)
            }
        }
    }

    private static let bodyColor = NSColor(
        calibratedRed: 0x0e / 255, green: 0x7a / 255, blue: 0x48 / 255, alpha: 1)
    private static let eyeWhite = NSColor(
        calibratedRed: 0xf8 / 255, green: 0xf3 / 255, blue: 0xe8 / 255, alpha: 1)
    private static let pupilColor = NSColor(
        calibratedRed: 0x18 / 255, green: 0x14 / 255, blue: 0x0f / 255, alpha: 1)

    private static let gridWidth: CGFloat = 16
    private static let gridHeight: CGFloat = 13
    static let aspectRatio: CGFloat = gridHeight / gridWidth

    private var facingLeft = false
    private var legFrameA = true
    private var blinking = false
    private var look: Look = .bottomRight

    private var legTimer: Timer?
    private var blinkWorkItem: DispatchWorkItem?
    private var lookWorkItem: DispatchWorkItem?

    private var laneMinX: CGFloat = 0
    private var laneMaxX: CGFloat = 0
    private var walking = false

    func configureLane(width laneWidth: CGFloat) {
        laneMinX = frame.minX
        laneMaxX = max(laneMinX, laneMinX + laneWidth - frame.width)
        walking = laneMaxX > laneMinX
    }

    func startAnimating() {
        stopAnimating()
        legTimer = Timer.scheduledTimer(withTimeInterval: 0.34, repeats: true) { [weak self] _ in
            self?.stepFrame()
        }
        scheduleBlink()
        scheduleLook()
    }

    func stopAnimating() {
        legTimer?.invalidate()
        legTimer = nil
        blinkWorkItem?.cancel()
        blinkWorkItem = nil
        lookWorkItem?.cancel()
        lookWorkItem = nil
    }

    deinit {
        legTimer?.invalidate()
        blinkWorkItem?.cancel()
        lookWorkItem?.cancel()
    }

    private func stepFrame() {
        legFrameA.toggle()
        if walking {
            let step: CGFloat = facingLeft ? -4 : 4
            var nextX = frame.minX + step
            if nextX <= laneMinX {
                nextX = laneMinX
                facingLeft = false
            } else if nextX >= laneMaxX {
                nextX = laneMaxX
                facingLeft = true
            }
            frame.origin.x = nextX
        }
        needsDisplay = true
    }

    private func scheduleBlink() {
        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.blinking = true
            self.needsDisplay = true
            let close = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.blinking = false
                self.needsDisplay = true
                self.scheduleBlink()
            }
            self.blinkWorkItem = close
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: close)
        }
        blinkWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2 + Double.random(in: 0...2.0), execute: item)
    }

    private func scheduleLook() {
        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let options = Look.allCases.filter { $0 != self.look }
            self.look = options.randomElement() ?? self.look
            self.needsDisplay = true
            self.scheduleLook()
        }
        lookWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 + Double.random(in: 0...3.5), execute: item)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let unit = bounds.width / Self.gridWidth

        ctx.saveGState()
        if facingLeft {
            ctx.translateBy(x: bounds.width, y: 0)
            ctx.scaleBy(x: -1, y: 1)
        }

        func fill(_ gx: CGFloat, _ gy: CGFloat, _ gw: CGFloat, _ gh: CGFloat, _ color: NSColor) {
            let y = bounds.height - (gy + gh) * unit
            color.setFill()
            NSBezierPath(rect: NSRect(x: gx * unit, y: y, width: gw * unit, height: gh * unit))
                .fill()
        }

        fill(8, 0, 1, 2, Self.bodyColor)
        fill(5, 2, 6, 1, Self.bodyColor)
        fill(3, 3, 10, 1, Self.bodyColor)
        fill(2, 4, 12, 5, Self.bodyColor)
        fill(3, 9, 10, 1, Self.bodyColor)

        if blinking {
            fill(5, 6, 2, 1, Self.pupilColor)
            fill(9, 6, 2, 1, Self.pupilColor)
        } else {
            fill(5, 5, 2, 2, Self.eyeWhite)
            fill(9, 5, 2, 2, Self.eyeWhite)
            let (lookX, lookY) = look.offset
            fill(5 + lookX, 5 + lookY, 1, 1, Self.pupilColor)
            fill(9 + lookX, 5 + lookY, 1, 1, Self.pupilColor)
        }

        let leftLeg: CGFloat = legFrameA ? 2 : 1
        let rightLeg: CGFloat = legFrameA ? 1 : 2
        fill(5, 10, 2, leftLeg, Self.bodyColor)
        fill(9, 10, 2, rightLeg, Self.bodyColor)

        ctx.restoreGState()
    }
}
