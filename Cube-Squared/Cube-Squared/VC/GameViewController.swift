import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak var hpContainer: UIStackView!
    @IBOutlet weak var scoreImage: UIImageView!
    @IBOutlet weak var scoreLabel: UILabel!
    
    var scene: GameScene!
    var game = Game(prefs: .default)
    
    var wickView = WickView(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        startGame()
        setupUI()
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
    
    func setupUI() {
        wickView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(wickView)
        
        NSLayoutConstraint.activate([
            wickView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            wickView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -view.bounds.width / 2),
            wickView.widthAnchor.constraint(equalToConstant: 200),
            wickView.heightAnchor.constraint(equalToConstant: 16)
        ])
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
            wickView.fire(with: game.coinLifetime)
        case .coinDisappeared(let c):
            scene.removeCoin(at: c, eaten: false)
            wickView.putOut()
        case .coinEaten(let c):
            scene.removeCoin(at: c, eaten: true)
            wickView.putOut()
            
        case .scoreChanged(let newScore):
            updateScore(new: newScore)
        case .hpChanged(let newHp):
            updateHP(new: newHp)
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

// MARK: - UI

private extension GameViewController {
    func updateScore(new: Int) {
        scoreLabel.text = String(new)
    }
    
    func updateHP(new: Int) {
        hpContainer.subviews.forEach { $0.removeFromSuperview() }
        guard new > 0 else { return }
        for _ in 1...new {
            let hp = generateHpImage()
            hpContainer.addArrangedSubview(hp)
            NSLayoutConstraint.activate([
                hp.heightAnchor.constraint(equalToConstant: 40),
                hp.widthAnchor.constraint(equalToConstant: 40)
            ])
        }
    }
    
    func generateHpImage() -> UIImageView {
        UIImageView(image: Images.hp)
    }
}
