import SpriteKit
import GameplayKit

protocol GameSceneDelegate: AnyObject {
    func pan(to dirs: [Direction], rolling: Bool)
    func coinExpired(at c: Coordinate)
    func traceExpired(at c: Coordinate)
}

class GameScene: SKScene {
    private enum Constants {
        static let tileSize = CGSize(width: 40, height: 40)
        static let moveDuration: TimeInterval = 0.1
        static let rollDuration: TimeInterval = 0.06
    }
    
    weak var gameSceneDelegate: GameSceneDelegate?
    private var prefs: Preferences
    
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
                cube?.color = .red
                return
            }
            switch rollingDirection {
            case .top:
                cube?.color = .blue
            case .bottom:
                cube?.color = .orange
            case .left:
                cube?.color = .purple
            case .right:
                cube?.color = .black
            }
            
        }
    }
    
    // MARK: - SKScene
    
    init(size: CGSize, prefs: Preferences) {
        self.prefs = prefs
        super.init(size: size)
        
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let layerPosition = CGPoint(
            x: -Constants.tileSize.width * CGFloat(prefs.fieldSize.width) / 2,
            y: -Constants.tileSize.height * CGFloat(prefs.fieldSize.height) / 2
        )
        
        addChild(bottomLayer)
        addChild(midLayer)
        addChild(topLayer)
        
        bottomLayer.position = layerPosition
        midLayer.position = layerPosition
        topLayer.position = layerPosition
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
                let emptyTile = SKSpriteNode(color: .gray, size: Constants.tileSize)
                bottomLayer.addChild(emptyTile)
                let c = Coordinate(x: x, y: y)
                emptyTile.position = point(for: c)
                emptyTiles[c] = emptyTile
            }
        }
    }
    
    func placeCube(at c: Coordinate) {
        let newCube = SKSpriteNode(color: .red, size: Constants.tileSize)
        topLayer.addChild(newCube)
        newCube.position = point(for: c)
        
        cube = newCube
    }
    
    func moveCube(to d: Direction, rolling: Bool) {
        guard let cube, let newC = convert(point: cube.position)?.shifted(to: d) else { return }
        
        if rolling, case .registering = ggr.state {
            self.rollingDirection = d
        }
        Haptics.shared.playSoft()
        isCubeMoving = true
        cube.run(.group([
            .move(to: point(for: newC), duration: rolling ? Constants.rollDuration : Constants.moveDuration),
            SoundFX.rollSound
        ])) { [weak self] in
            guard let self else { return }
            self.isCubeMoving = false
        }
    }
    
    func addTrace(at c: Coordinate, time: TimeInterval) {
        removeTrace(at: c)
        let trace = SKSpriteNode(color: .green, size: Constants.tileSize)
        midLayer.addChild(trace)
        trace.position = point(for: c)
        traces[c] = trace
        
        trace.run(.fadeOut(withDuration: time), completion: { [weak self] in
            self?.gameSceneDelegate?.traceExpired(at: c)
        })
    }
    
    func removeTrace(at c: Coordinate) {
        traces.removeValue(forKey: c)?.removeFromParent()
    }
    
    func addCoin(at c: Coordinate, time: TimeInterval) {
        let coin = SKSpriteNode(color: .yellow, size: Constants.tileSize)
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
        rollingDirection = nil
    }
}

// MARK: - Geometry

private extension GameScene {
    func point(for c: Coordinate) -> CGPoint {
        CGPoint(
            x: CGFloat(c.x) * Constants.tileSize.width + Constants.tileSize.width / 2,
            y: CGFloat(c.y) * Constants.tileSize.height + Constants.tileSize.height / 2
        )
    }
    
    func convert(point: CGPoint) -> Coordinate? {
        if point.x >= 0 && point.x < CGFloat(prefs.fieldSize.width) * Constants.tileSize.width &&
            point.y >= 0 && point.y < CGFloat(prefs.fieldSize.height) * Constants.tileSize.height {
            return .init(x: Int(point.x / Constants.tileSize.width), y: Int(point.y / Constants.tileSize.height))
        } else {
            return nil
        }
    }
}
