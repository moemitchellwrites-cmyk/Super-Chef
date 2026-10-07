#if canImport(SwiftUI) && canImport(SpriteKit)
import SpriteKit
import PantryGame

/// The vessel scene: one wok on a burner. Ingredients fall in and pile up under
/// physics, and every sound cue has its visual twin here (sparks and steam, bubbles,
/// droplets, a shaking pan, a flaring burner) plus a comic-strip word, so the round
/// reads the same with the sound off.
///
/// Placeholder art throughout: shapes and emoji until PB-011.
final class WokScene: SKScene {
    static let logicalSize = CGSize(width: 390, height: 260)

    private let centerX: CGFloat = 195
    private let rimY: CGFloat = 150
    private let radius: CGFloat = 140
    private let depth: CGFloat = 86
    private let wall: CGFloat = 8
    private let pieceRadius: CGFloat = 12

    private let wok = SKNode()
    private let flame = SKNode()
    private let rimGlow = SKShapeNode()
    private var pieces: [String: [SKNode]] = [:]
    private var generator = SeededGenerator(seed: 0xD15)

    /// The scene, built and ready for a `SpriteView`.
    static func make() -> WokScene {
        let scene = WokScene(size: logicalSize)
        scene.scaleMode = .aspectFit
        scene.backgroundColor = SKColor(red: 0.99, green: 0.95, blue: 0.87, alpha: 1)
        scene.physicsWorld.gravity = CGVector(dx: 0, dy: -6)
        scene.buildBurner()
        scene.buildWok()
        return scene
    }

    // MARK: Building

    private func bowlPoints(inset: CGFloat) -> [CGPoint] {
        let segments = 24
        return (0...segments).map { index in
            let angle = CGFloat.pi + CGFloat.pi * CGFloat(index) / CGFloat(segments)
            return CGPoint(x: centerX + (radius - inset) * cos(angle), y: rimY + (depth - inset) * sin(angle))
        }
    }

    private func closedPath(_ points: [CGPoint]) -> CGPath {
        let path = CGMutablePath()
        path.addLines(between: points)
        path.closeSubpath()
        return path
    }

    private func buildWok() {
        let shell = SKShapeNode(path: closedPath(bowlPoints(inset: 0)))
        shell.fillColor = SKColor(red: 0.17, green: 0.18, blue: 0.20, alpha: 1)
        shell.strokeColor = .clear
        wok.addChild(shell)

        let inside = SKShapeNode(path: closedPath(bowlPoints(inset: wall)))
        inside.fillColor = SKColor(red: 0.33, green: 0.34, blue: 0.37, alpha: 1)
        inside.strokeColor = .clear
        wok.addChild(inside)

        for side in [CGFloat(-1), 1] {
            let handle = SKShapeNode(rectOf: CGSize(width: 34, height: 11), cornerRadius: 5)
            handle.position = CGPoint(x: centerX + side * (radius + 12), y: rimY - 5)
            handle.fillColor = SKColor(red: 0.17, green: 0.18, blue: 0.20, alpha: 1)
            handle.strokeColor = .clear
            wok.addChild(handle)
        }

        let rim = CGMutablePath()
        rim.move(to: CGPoint(x: centerX - radius, y: rimY))
        rim.addLine(to: CGPoint(x: centerX + radius, y: rimY))
        rimGlow.path = rim
        rimGlow.strokeColor = SKColor(red: 1.0, green: 0.55, blue: 0.10, alpha: 1)
        rimGlow.lineWidth = 6
        rimGlow.lineCap = .round
        rimGlow.alpha = 0
        rimGlow.zPosition = 5
        wok.addChild(rimGlow)

        // The inside of the bowl, with tall sides above the rim so a pile can't spill out of the scene.
        let interior = bowlPoints(inset: wall)
        let edge = CGMutablePath()
        edge.move(to: CGPoint(x: centerX - radius + wall, y: WokScene.logicalSize.height + 400))
        for point in interior {
            edge.addLine(to: point)
        }
        edge.addLine(to: CGPoint(x: centerX + radius - wall, y: WokScene.logicalSize.height + 400))
        wok.physicsBody = SKPhysicsBody(edgeChainFrom: edge)
        wok.physicsBody?.friction = 0.6

        wok.zPosition = 1
        addChild(wok)
    }

    private func buildBurner() {
        let burner = SKShapeNode(rectOf: CGSize(width: 150, height: 14), cornerRadius: 6)
        burner.position = CGPoint(x: centerX, y: 24)
        burner.fillColor = SKColor(red: 0.45, green: 0.45, blue: 0.48, alpha: 1)
        burner.strokeColor = .clear
        burner.zPosition = 0
        addChild(burner)

        flame.position = CGPoint(x: centerX, y: 31)
        flame.zPosition = 0.5
        flame.setScale(0.01)
        flame.isHidden = true
        for index in 0..<5 {
            let tongue = SKNode()
            tongue.position = CGPoint(x: CGFloat(index - 2) * 24, y: 0)
            let outer = SKShapeNode(ellipseOf: CGSize(width: 20, height: 36))
            outer.position = CGPoint(x: 0, y: 18)
            outer.fillColor = SKColor(red: 1.0, green: 0.48, blue: 0.10, alpha: 1)
            outer.strokeColor = .clear
            let inner = SKShapeNode(ellipseOf: CGSize(width: 10, height: 20))
            inner.position = CGPoint(x: 0, y: 12)
            inner.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.25, alpha: 1)
            inner.strokeColor = .clear
            tongue.addChild(outer)
            tongue.addChild(inner)
            let beat = 0.16 + Double(index) * 0.03
            tongue.run(.repeatForever(.sequence([
                .scaleY(to: 1.22, duration: beat),
                .scaleY(to: 0.92, duration: beat),
            ])))
            flame.addChild(tongue)
        }
        addChild(flame)
    }

    // MARK: Ingredients

    /// Scene x for a drop at `fraction` of the way across the view, kept inside the wok's mouth.
    func dropX(fraction: CGFloat) -> CGFloat {
        clampX(fraction * WokScene.logicalSize.width)
    }

    private func clampX(_ x: CGFloat) -> CGFloat {
        let reach = radius - wall - pieceRadius - 30
        return min(max(x, centerX - reach), centerX + reach)
    }

    private func random(_ range: ClosedRange<CGFloat>) -> CGFloat {
        range.lowerBound + CGFloat(generator.unit()) * (range.upperBound - range.lowerBound)
    }

    /// Makes the pile for an ingredient `count` pieces big, dropping new ones in at `x`.
    func setPieces(for id: String, count: Int, look: IngredientLook, atX x: CGFloat? = nil) {
        var nodes = pieces[id] ?? []
        while nodes.count > max(count, 0) {
            let node = nodes.removeLast()
            node.physicsBody = nil
            node.run(.sequence([
                .group([.fadeOut(withDuration: 0.15), .scale(to: 0.3, duration: 0.15)]),
                .removeFromParent(),
            ]))
        }
        let landing = x ?? random((centerX - 70)...(centerX + 70))
        while nodes.count < count {
            let node = makePiece(look)
            node.position = CGPoint(
                x: clampX(landing + random(-16...16)),
                y: rimY + 46 + CGFloat(nodes.count) * 16 + random(0...8)
            )
            addChild(node)
            nodes.append(node)
        }
        pieces[id] = nodes.isEmpty ? nil : nodes
    }

    private func makePiece(_ look: IngredientLook) -> SKNode {
        let piece = SKShapeNode(circleOfRadius: pieceRadius)
        piece.fillColor = SKColor(red: look.red, green: look.green, blue: look.blue, alpha: 1)
        piece.strokeColor = SKColor(white: 0, alpha: 0.25)
        piece.lineWidth = 1
        piece.zPosition = 3
        let glyph = SKLabelNode(text: look.emoji)
        glyph.fontSize = 15
        glyph.verticalAlignmentMode = .center
        glyph.horizontalAlignmentMode = .center
        piece.addChild(glyph)
        let body = SKPhysicsBody(circleOfRadius: pieceRadius)
        body.restitution = 0.2
        body.friction = 0.5
        body.linearDamping = 0.5
        body.angularDamping = 0.8
        piece.physicsBody = body
        return piece
    }

    func clear() {
        for nodes in pieces.values {
            for node in nodes {
                node.removeFromParent()
            }
        }
        pieces = [:]
        flame.removeAllActions()
        flame.setScale(0.01)
        flame.isHidden = true
    }

    /// The rim lights up while an ingredient is held over the wok.
    func setDropHighlight(_ on: Bool) {
        rimGlow.removeAllActions()
        rimGlow.run(.fadeAlpha(to: on ? 1 : 0, duration: 0.1))
    }

    // MARK: Visual twins

    /// Sets the burner for a cooking method (`level` 0...1) with a flare: the flame cue's twin.
    func setFlame(level: CGFloat) {
        let settled = 0.45 + 0.55 * min(max(level, 0), 1)
        flame.isHidden = false
        flame.removeAllActions()
        flame.run(.sequence([
            .scale(to: settled * 1.5, duration: 0.1),
            .scale(to: settled, duration: 0.25),
        ]))
        popWord(SoundCue.flame.word, at: CGPoint(x: centerX, y: 78), color: SKColor(red: 0.85, green: 0.20, blue: 0.10, alpha: 1))
    }

    /// Plays the motion that goes with an ingredient's sound cue, where it landed.
    func playTwin(_ cue: SoundCue, atX x: CGFloat? = nil) {
        let origin = CGPoint(x: clampX(x ?? centerX), y: rimY - 8)
        let color: SKColor
        switch cue {
        case .sizzle:
            color = SKColor(red: 0.95, green: 0.50, blue: 0.05, alpha: 1)
            burst(count: 10, at: origin, size: 2...4, color: SKColor(red: 1.0, green: 0.75, blue: 0.15, alpha: 1),
                  spread: 60, rise: 30...80, duration: 0.45, falls: true)
            burst(count: 4, at: origin, size: 8...13, color: SKColor(white: 1, alpha: 0.75),
                  spread: 22, rise: 60...100, duration: 0.9, grow: 2.2)
        case .boil:
            color = SKColor(red: 0.15, green: 0.45, blue: 0.80, alpha: 1)
            burst(count: 8, at: origin, size: 4...9, color: SKColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1),
                  spread: 46, rise: 30...70, duration: 0.8, grow: 1.5, hollow: true)
        case .splash:
            color = SKColor(red: 0.05, green: 0.55, blue: 0.60, alpha: 1)
            burst(count: 9, at: origin, size: 3...6, color: SKColor(red: 0.35, green: 0.70, blue: 0.90, alpha: 1),
                  spread: 80, rise: 40...85, duration: 0.55, falls: true)
        case .clatter:
            color = SKColor(red: 0.50, green: 0.33, blue: 0.15, alpha: 1)
            shake()
            burst(count: 6, at: origin, size: 2...4, color: SKColor(red: 0.62, green: 0.45, blue: 0.25, alpha: 1),
                  spread: 50, rise: 25...55, duration: 0.4, falls: true)
        case .flame:
            setFlame(level: 1)
            return
        }
        popWord(cue.word, at: CGPoint(x: origin.x, y: rimY + 40), color: color)
    }

    private func burst(count: Int, at origin: CGPoint, size: ClosedRange<CGFloat>, color: SKColor, spread: CGFloat,
                       rise: ClosedRange<CGFloat>, duration: TimeInterval, grow: CGFloat = 1,
                       falls: Bool = false, hollow: Bool = false) {
        for _ in 0..<count {
            let dot = SKShapeNode(circleOfRadius: random(size))
            dot.fillColor = hollow ? .clear : color
            dot.strokeColor = hollow ? color : .clear
            dot.lineWidth = hollow ? 1.5 : 0
            dot.position = CGPoint(x: origin.x + random(-14...14), y: origin.y + random(-4...8))
            dot.zPosition = 10
            addChild(dot)

            let dx = random(-spread...spread)
            let dy = random(rise)
            let travel: SKAction
            if falls {
                let up = SKAction.moveBy(x: dx / 2, y: dy, duration: duration / 2)
                up.timingMode = .easeOut
                let down = SKAction.moveBy(x: dx / 2, y: -dy * 0.9, duration: duration / 2)
                down.timingMode = .easeIn
                travel = .sequence([up, down])
            } else {
                let up = SKAction.moveBy(x: dx, y: dy, duration: duration)
                up.timingMode = .easeOut
                travel = up
            }
            dot.run(.sequence([
                .group([
                    travel,
                    .scale(to: grow, duration: duration),
                    .sequence([.wait(forDuration: duration * 0.55), .fadeOut(withDuration: duration * 0.45)]),
                ]),
                .removeFromParent(),
            ]))
        }
    }

    private func shake() {
        wok.removeAction(forKey: "shake")
        wok.position = .zero
        let step = 0.04
        wok.run(.sequence([
            .moveBy(x: 5, y: 0, duration: step),
            .moveBy(x: -10, y: 0, duration: step),
            .moveBy(x: 8, y: 0, duration: step),
            .moveBy(x: -6, y: 0, duration: step),
            .moveBy(x: 3, y: 0, duration: step),
        ]), withKey: "shake")
    }

    private func popWord(_ word: String, at point: CGPoint, color: SKColor) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = word
        label.fontSize = 24
        label.fontColor = color
        label.position = CGPoint(x: min(max(point.x, 70), WokScene.logicalSize.width - 70), y: point.y)
        label.zRotation = random(-0.14...0.14)
        label.zPosition = 20
        label.setScale(0.4)
        addChild(label)
        label.run(.sequence([
            .group([
                .scale(to: 1, duration: 0.12),
                .moveBy(x: 0, y: 34, duration: 0.9),
                .sequence([.wait(forDuration: 0.55), .fadeOut(withDuration: 0.35)]),
            ]),
            .removeFromParent(),
        ]))
    }
}
#endif
