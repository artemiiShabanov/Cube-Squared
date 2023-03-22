import SpriteKit
import GameplayKit

protocol GameSceneDelegate: AnyObject {
    func pan(to dirs: [Direction], rolling: Bool)
    func coinExpired(at c: Coordinate)
    func traceExpired(at c: Coordinate)
}

class GameScene: SKScene {
    private enum Constants {
        static let offset: CGFloat = 90
        static let moveDuration: TimeInterval = 0.1
        static let rollDuration: TimeInterval = 0.07
    }
    
    weak var gameSceneDelegate: GameSceneDelegate?
    private var prefs: Preferences
    private var tileSize: CGSize
    
    // Layers
    let bottomLayer = SKNode()
    let midLayer = SKNode()
    let topLayer = SKNode()
    
    // Nodes
    var emptyTiles: [Coordinate: SKSpriteNode] = [:]
    var coins: [Coordinate: SKSpriteNode] = [:]
    var traces: [Coordinate: SKSpriteNode] = [:]
    var cube: SKSpriteNode?
    
    // Gestures
    let ggr = GameGestureRecognizer()
    
    // State
    private var isCubeMoving = false
    private var rollingDirection: Direction? {
        didSet {
            guard let rollingDirection else {
//                cube?.color = .red
                return
            }
            switch rollingDirection {
            case .top:
                cube?.zRotation = .pi / 2
            case .bottom:
                cube?.zRotation = -.pi / 2
            case .left:
                cube?.zRotation = .pi
            case .right:
                cube?.zRotation = 0
            }
            
        }
    }
    
    // MARK: - SKScene
    
    init(size: CGSize, prefs: Preferences) {
        self.prefs = prefs
        let edge = (size.width - Constants.offset) / CGFloat(prefs.fieldSize.width)
        self.tileSize = .init(width: edge, height: edge)
        super.init(size: size)
        
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let layerPosition = CGPoint(
            x: -tileSize.width * CGFloat(prefs.fieldSize.width) / 2,
            y: -tileSize.height * CGFloat(prefs.fieldSize.height) / 2
        )
        
        addChild(bottomLayer)
        addChild(midLayer)
        addChild(topLayer)
        
        bottomLayer.position = layerPosition
        midLayer.position = layerPosition
        topLayer.position = layerPosition
        
        backgroundColor = .black
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    override func didMove(to view: SKView) {
        ggr.scene = self
        ggr.onRegistered = { [weak self] in
            self?.handleSwipe()
        }
        ggr.onChangedDirection = { [weak self] in
            self?.handleDirectionChange()
        }
        ggr.onEnded = { [weak self] in
            self?.handleEnded()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)     { if let touch = touches.first { ggr.touchBegan(touch) } }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)     { if let touch = touches.first { ggr.touchMoved(touch) } }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)     { if let touch = touches.first { ggr.touchEnded(touch) } }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { if let touch = touches.first { ggr.touchCancelled(touch) } }
    override func update(_ currentTime: TimeInterval) { }
    
}

// MARK: API
 
extension GameScene {
    func reset() {
        for key in emptyTiles.keys {
            emptyTiles.removeValue(forKey: key)?.removeFromParent()
        }
        for key in coins.keys {
            coins.removeValue(forKey: key)?.removeFromParent()
        }
        for key in traces.keys {
            traces.removeValue(forKey: key)?.removeFromParent()
        }
        cube?.removeFromParent()
        
        for x in 0..<prefs.fieldSize.width {
            for y in 0..<prefs.fieldSize.height {
                let emptyTile = generateEmptyTile()
                bottomLayer.addChild(emptyTile)
                let c = Coordinate(x: x, y: y)
                emptyTile.position = point(for: c)
                emptyTiles[c] = emptyTile
            }
        }
    }
    
    func placeCube(at c: Coordinate) {
        let newCube = generateCube()
        topLayer.addChild(newCube)
        newCube.position = point(for: c)
        
        cube = newCube
    }
    
    func moveCube(to d: Direction, rolling: Bool) {
        guard let cube, let newC = convert(point: cube.position)?.shifted(to: d) else { return }
        
        self.rollingDirection = d
        let duration = rolling ? Constants.rollDuration : Constants.moveDuration
        
        Haptics.shared.playSoft()
        isCubeMoving = true
        cube.run(.group([
            .move(to: point(for: newC), duration: duration),
            .animate(with: Assets.cubeRoll.map { .init(imageNamed: $0) }, timePerFrame: duration / Double(Assets.cubeRoll.count)),
            SoundFX.rollSound
        ])) { [weak self] in
            guard let self else { return }
            self.isCubeMoving = false
        }
    }
    
    func addTrace(at c: Coordinate, time: TimeInterval) {
        removeTrace(at: c)
        let trace = generateTrace()
        midLayer.addChild(trace)
        trace.position = point(for: c)
        traces[c] = trace
        
        trace.alpha = 0.8
        trace.run(.sequence([
            .fadeAlpha(by: -0.6, duration: time - 1),
            .wait(forDuration: 0.9),
            .scale(to: 0, duration: 0.1)
        ])) { [weak self] in
            self?.gameSceneDelegate?.traceExpired(at: c)
        }
    }
    
    func removeTrace(at c: Coordinate) {
        traces.removeValue(forKey: c)?.removeFromParent()
    }
    
    func addCoin(at c: Coordinate, time: TimeInterval) {
        let coin = generateCoin()
        midLayer.addChild(coin)
        coin.position = point(for: c)
        coins[c] = coin
        
        coin.alpha = 0
        coin.xScale = 0.1
        coin.yScale = 0.1
        
        coin.run(.group([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2)
        ]), completion: {
            coin.run(.wait(forDuration: time), completion: { [weak self] in
                self?.gameSceneDelegate?.coinExpired(at: c)
            })
        })
    }
    
    func removeCoin(at c: Coordinate, eaten: Bool) {
        guard let coin = coins.removeValue(forKey: c) else {
            assertionFailure()
            return
        }
        coin.removeAllActions()
        if eaten {
            run(SoundFX.coinSound)
            Haptics.shared.playMedium()
        } else {
            Haptics.shared.playRigid()
        }
        coin.run(.fadeOut(withDuration: 0.2), completion: {
            coin.removeFromParent()
        })
    }
    
    func hitWall() {
        Haptics.shared.playRigid()
    }
}

// MARK: - Actions

private extension GameScene {
    func handleSwipe() {
        guard !isCubeMoving else { return }
        guard let dirs = ggr.state.directions else {
            assertionFailure()
            return
        }
        gameSceneDelegate?.pan(to: dirs, rolling: false)
    }
    func handleDirectionChange() {
        guard !isCubeMoving else { return }
        guard let dirs = ggr.state.directions else {
            assertionFailure()
            return
        }
        gameSceneDelegate?.pan(to: dirs, rolling: true)
    }
    func handleEnded() {
//        rollingDirection = nil
    }
}

// MARK: - Geometry

private extension GameScene {
    func point(for c: Coordinate) -> CGPoint {
        CGPoint(
            x: CGFloat(c.x) * tileSize.width + tileSize.width / 2,
            y: CGFloat(c.y) * tileSize.height + tileSize.height / 2
        )
    }
    
    func convert(point: CGPoint) -> Coordinate? {
        if point.x >= 0 && point.x < CGFloat(prefs.fieldSize.width) * tileSize.width &&
            point.y >= 0 && point.y < CGFloat(prefs.fieldSize.height) * tileSize.height {
            return .init(x: Int(point.x / tileSize.width), y: Int(point.y / tileSize.height))
        } else {
            return nil
        }
    }
}

// MARK: - Sprites

private extension GameScene {
    func generateEmptyTile() -> SKSpriteNode {
        generateTile(with: Assets.emptyTile)
    }
    
    func generateTrace() -> SKSpriteNode {
        generateTile(with: Assets.trace)
    }
    
    func generateCoin() -> SKSpriteNode {
        generateTile(with: Assets.coin)
    }
    
    func generateCube() -> SKSpriteNode {
        generateTile(with: Assets.cube)
    }
    
    func generateTile(with asset: String) -> SKSpriteNode {
        let emptyTile = SKSpriteNode(imageNamed: asset)
        emptyTile.size = tileSize
        return emptyTile
    }
}
