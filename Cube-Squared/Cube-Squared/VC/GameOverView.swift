import UIKit

final class GameOverView: UIView {
    private let coinImage = UIImageView(image: Images.c)
    private let scoreLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    func set(score: Int) {
        scoreLabel.text = String(score)
    }
    
    private func setupUI() {
        backgroundColor = .darkGray.withAlphaComponent(0.98)
        layer.cornerRadius = 20
        
        addSubview(coinImage)
        coinImage.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scoreLabel)
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        scoreLabel.textColor = .white
        
        NSLayoutConstraint.activate([
            coinImage.widthAnchor.constraint(equalToConstant: 60),
            coinImage.heightAnchor.constraint(equalToConstant: 60),
            coinImage.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -40),
            coinImage.centerYAnchor.constraint(equalTo: centerYAnchor),
            scoreLabel.centerXAnchor.constraint(equalTo: centerXAnchor, constant: +40),
            scoreLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
