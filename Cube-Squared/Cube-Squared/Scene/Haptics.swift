import UIKit

final class Haptics {
    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    
    static let shared = Haptics()
    private init() {}
    
    func playSoft() { soft.impactOccurred() }
    func playRigid() { rigid.impactOccurred() }
    func playMedium() { medium.impactOccurred() }
}
