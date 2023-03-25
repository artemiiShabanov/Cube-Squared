import UIKit

final class WickView: UIView {
    private let wick = UIView()
    private var widthConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        isUserInteractionEnabled = false
        
        addSubview(wick)
        wick.alpha = 0
        wick.backgroundColor = Colors.coin.withAlphaComponent(0.7)
        wick.translatesAutoresizingMaskIntoConstraints = false
        
        widthConstraint = wick.widthAnchor.constraint(equalTo: widthAnchor)
        NSLayoutConstraint.activate([
            wick.centerXAnchor.constraint(equalTo: centerXAnchor),
            wick.centerYAnchor.constraint(equalTo: centerYAnchor),
            wick.heightAnchor.constraint(equalTo: heightAnchor),
            widthConstraint
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        wick.layer.cornerRadius = wick.bounds.height / 2
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func fire(with time: TimeInterval, color: UIColor) {
        widthConstraint.constant = 0
        wick.backgroundColor = color.withAlphaComponent(0.7)
        layoutIfNeeded()
        UIView.animate(withDuration: 0.5) {
            self.wick.alpha = 1
        } completion: { _ in
            self.widthConstraint.constant = -self.bounds.width + 20
            UIView.animate(withDuration: time - 0.5, delay: 0.5, options: .curveEaseOut) {
                self.layoutIfNeeded()
            }
        }
    }
    
    func putOut() {
        wick.layer.removeAllAnimations()
        wick.alpha = 0
    }
}
