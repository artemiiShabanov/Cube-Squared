import UIKit
import SpriteKit
import GameplayKit
import SPConfetti

class GameViewController: UIViewController {
    @IBOutlet weak var gameOverPanel: GameOverView!
    @IBOutlet weak var hpContainer: UIStackView!
    @IBOutlet weak var scoreImage: UIImageView!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var maxScoreImage: UIImageView!
    @IBOutlet weak var maxScoreLabel: UILabel!
    @IBOutlet weak var topContainer: UIView!
    @IBOutlet weak var playPauseContainer: UIView!
    @IBOutlet weak var playPauseImageView: UIImageView!
    @IBOutlet weak var restartButton: UIButton!
    private var wickView = WickView(frame: .zero)
    
    private var tapGestureRecognizer: UITapGestureRecognizer!
    private var recordBroken = false
    
    var scene: GameScene!
    var game = Game(prefs: .default)
    
    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        startGame()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !UserDefaults.standard.seenOnboarding {
            present(OnboardingViewController(), animated: true)
            UserDefaults.standard.seenOnboarding = true
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions

extension GameViewController {
    @IBAction func restart() {
        wickView.putOut()
        startGame()
    }
    
    @objc func playPauseTap() {
        if scene.isPaused {
            resume()
        } else {
            pause()
        }
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
        recordBroken = false
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
        
        topContainer.layer.cornerRadius = 35
        playPauseContainer.layer.cornerRadius = 35
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
            
        case .coinAppeared(let c, let type):
            scene.addCoin(at: c, time: game.coinLifetime, type: type)
            wickView.fire(with: game.coinLifetime, color: type.color)
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
}

// MARK: - Game cycle

private extension GameViewController {
    func updateScore(new: Int) {
        scoreLabel.text = String(new)
        gameOverPanel.set(score: new)
        if new > UserDefaults.standard.maxScore {
            recordBroken = true
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
        playPauseContainer.isUserInteractionEnabled = false
        restartButton.isEnabled = false
        
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.hideGameOver))
        self.view.addGestureRecognizer(self.tapGestureRecognizer)
        
        wickView.putOut()
        
        if recordBroken {
            SPConfetti.startAnimating(.fullWidthToDown, particles: [.triangle, .arc, .heart])
        }
    }
    
    @objc func hideGameOver() {
        let skView = view as! SKView
        skView.isPaused = false
        
        scene.isUserInteractionEnabled = true
        gameOverPanel.alpha = 0
        playPauseContainer.isUserInteractionEnabled = true
        restartButton.isEnabled = true
        
        view.removeGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer = nil
        
        SPConfetti.stopAnimating()
        
        startGame()
    }
    
    func pause() {
        let skView = view as! SKView
        skView.isPaused = true
        
        scene.isUserInteractionEnabled = false
        scene.backgroundColor = Colors.paused
        scene.alpha = 0.7
        
        restartButton.isEnabled = false
        wickView.pauseLayer()
        playPauseImageView.image = UIImage.init(systemName: "play.fill")
    }
    
    func resume() {
        let skView = view as! SKView
        skView.isPaused = false
        
        scene.isUserInteractionEnabled = true
        scene.backgroundColor = Colors.bg
        scene.alpha = 1
        
        restartButton.isEnabled = true
        wickView.resumeLayer()
        playPauseImageView.image = UIImage.init(systemName: "pause.fill")
    }
}
