import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    var scene: GameScene!
    var game = Game(prefs: .default)
    
    var pauseButton = UIButton()
    var currentScoreLabel = UILabel()
    var maxScoreLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        startGame()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Setup

private extension GameViewController {
    func setupScene() {
        let skView = view as! SKView
        skView.isMultipleTouchEnabled = false
        skView.showsFPS = true
        skView.showsNodeCount = true
        
        scene = GameScene(size: skView.bounds.size, prefs: .default)
        scene.scaleMode = .aspectFill
        
        scene.gameSceneDelegate = self
        game.delegate = self
        
        skView.presentScene(scene)
    }
    
    func startGame() {
        scene.reset()
        game.startGame()
    }
}

// MARK: - GameEventDelegate

extension GameViewController: GameEventDelegate {
    func handle(event: GameEvent) {
        switch event {
        case .cubeAppeared(let c):
            scene.placeCube(at: c)
        case .cubeMoved(let d, let rolling):
            scene.moveCube(to: d, rolling: rolling)
        case .traceAppeared(let c):
            scene.addTrace(at: c, time: game.traceLifetime)
        case .traceDisappeared(c: let c):
            scene.removeTrace(at: c)
        case .coinAppeared(let c):
            scene.addCoin(at: c, time: game.coinLifetime)
        case .coinDisappeared(let c):
            scene.removeCoin(at: c, eaten: false)
        case .coinEaten(let c):
            scene.removeCoin(at: c, eaten: true)
        }
    }
}

// MARK: - GameSceneDelegate

extension GameViewController: GameSceneDelegate {
    func pan(to dirs: [Direction], rolling: Bool) {
        if rolling {
            game.rollIfPossible(to: dirs)
        } else {
            if !game.moveIfPossible(to: dirs) {
                scene.hitWall()
            }
        }
    }
    
    func coinExpired(at c: Coordinate) {
        game.expiredCoin(at: c)
    }
    
    func traceExpired(at c: Coordinate) {
        game.expiredTrace(at: c)
    }
}
