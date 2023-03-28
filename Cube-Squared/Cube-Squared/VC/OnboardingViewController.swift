import UIKit
import AVKit
import AVFoundation

fileprivate enum OnboardingStep: CaseIterable {
    case swipe
    case drag
    
    var video: String {
        switch self {
        case .swipe:
            return "swipe"
        case .drag:
            return "drag"
        }
    }
    
    var text: String {
        switch self {
        case .swipe:
            return "Swipe to roll"
        case .drag:
            return "Drag on red cells to roll faster"
        }
    }
}

final class OnboardingViewController: UIViewController {
    private let steps = OnboardingStep.allCases
    private var currentStep = 0
    private let container = UIView()
    private let label = UILabel()
    private let nextButton = UIButton(configuration: .tinted())
    
    private var playerLooper: AVPlayerLooper?
    private var queuePlayer: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Colors.bg//.withAlphaComponent(0.9)
        view.addSubview(nextButton)
        nextButton.addTarget(self, action: #selector(tap), for: .touchUpInside)
        nextButton.setTitle("Next", for: .normal)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.tintColor = .white
        
        view.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .black
        container.layer.cornerRadius = 20
        container.layer.borderWidth = 2
        container.layer.borderColor = UIColor.darkGray.cgColor
        
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .title2)
        label.numberOfLines = 2
        label.textColor = .lightGray
        label.textAlignment = .center
        
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -50),
            container.heightAnchor.constraint(equalTo: view.widthAnchor, constant: -50),
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.topAnchor.constraint(equalTo: container.bottomAnchor, constant: 25),
            label.widthAnchor.constraint(equalTo: container.widthAnchor),
            
            nextButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            nextButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -32),
            nextButton.heightAnchor.constraint(equalToConstant: 52),
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        next()
    }

    private func next() {
        self.queuePlayer?.pause()
        self.playerLayer?.removeFromSuperlayer()
        
        let step = steps[currentStep]
        guard let path = Bundle.main.path(forResource: step.video, ofType: "mp4") else {
            return
        }
        
        let asset = AVAsset(url: URL(fileURLWithPath: path))
        let playerItem = AVPlayerItem(asset: asset)
        
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        let playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        let playerLayer = AVPlayerLayer(player: queuePlayer)
        
        playerLayer.frame = .init(
            origin: .init(x: (container.bounds.width - 250) / 2, y: 16),
            size: .init(width: 250, height: 226)
        )
        self.container.layer.addSublayer(playerLayer)
        queuePlayer.play()
        
        label.text = step.text
        
        self.queuePlayer = queuePlayer
        self.playerLooper = playerLooper
        self.playerLayer = playerLayer
    }
    
    @objc private func tap() {
        if currentStep == steps.count - 1 {
            dismiss(animated: true)
        } else {
            currentStep += 1
            if currentStep == steps.count - 1 {
                nextButton.setTitle("Finish", for: .normal)
            }
            next()
        }
    }
}
