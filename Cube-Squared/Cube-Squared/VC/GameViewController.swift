import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak var gameOverPanel: GameOverView!
    @IBOutlet weak var hpContainer: UIStackView!
    @IBOutlet weak var scoreImage: UIImageView!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var maxScoreImage: UIImageView!
    @IBOutlet weak var maxScoreLabel: UILabel!
    @IBOutlet weak var playPauseContainer: UIView!
    @IBOutlet weak var playPauseImageView: UIImageView!
    
    private var tapGestureRecognizer: UITapGestureRecognizer!
    
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
        scene.backgroundColor = Colors.bg
        gameOverPanel.alpha = 0
        
        NSLayoutConstraint.activate([
            wickView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            wickView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -view.bounds.width / 2),
            wickView.widthAnchor.constraint(equalToConstant: 200),
            wickView.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        maxScoreLabel.text = String(UserDefaults.standard.maxScore)
        
        playPauseContainer.layer.borderColor = UIColor.lightGray.cgColor
        playPauseContainer.layer.cornerRadius = 40
        playPauseContainer.layer.borderWidth = 3
        playPauseContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(playPauseTap)))
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
            
        case .coinAppeared(let c, let is5):
            scene.addCoin(at: c, time: game.coinLifetime, is5: is5)
            wickView.fire(with: game.coinLifetime, color: is5 ? Colors.coin5 : Colors.coin)
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
            
        case .gameOver:
            showGameOver()
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
    func generateHpImage() -> UIImageView {
        UIImageView(image: Images.hp)
    }
    
    @objc func playPauseTap() {
        if scene.isPaused {
            resume()
        } else {
            pause()
        }
    }
}

// MARK: - Game cycle

private extension GameViewController {
    func updateScore(new: Int) {
        scoreLabel.text = String(new)
        gameOverPanel.set(score: new)
        if new > UserDefaults.standard.maxScore {
            maxScoreLabel.text = String(new)
            UserDefaults.standard.maxScore = new
        }
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
    
    func showGameOver() {
        let skView = view as! SKView
        skView.isPaused = true
        
        scene.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.3) {
            self.gameOverPanel.alpha = 1
        }
        wickView.putOut()
        playPauseContainer.isUserInteractionEnabled = false
        
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.hideGameOver))
        self.view.addGestureRecognizer(self.tapGestureRecognizer)
    }
    
    @objc func hideGameOver() {
        let skView = view as! SKView
        skView.isPaused = false
        
        scene.isUserInteractionEnabled = true
        gameOverPanel.alpha = 0
        playPauseContainer.isUserInteractionEnabled = true
        
        
        view.removeGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer = nil
        
        startGame()
    }
    
    func pause() {
        let skView = view as! SKView
        skView.isPaused = true
        
        scene.isUserInteractionEnabled = false
        scene.backgroundColor = Colors.paused
        scene.alpha = 0.7
        wickView.pauseLayer()
        playPauseImageView.image = UIImage.init(systemName: "play.fill")
    }
    
    func resume() {
        let skView = view as! SKView
        skView.isPaused = false
        
        scene.isUserInteractionEnabled = true
        scene.backgroundColor = Colors.bg
        scene.alpha = 1
        wickView.resumeLayer()
        playPauseImageView.image = UIImage.init(systemName: "pause.fill")
    }
}
