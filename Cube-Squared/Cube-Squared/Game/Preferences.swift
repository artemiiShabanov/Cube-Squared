import Foundation

struct Preferences {
    let fieldSize: Size
    let traceLifetime: TimeInterval
    let coinLifetime: TimeInterval
    let startingHp: Int
    
    static let `default` = Preferences(
        fieldSize: .init(width: 5, height: 5),
        traceLifetime: 5,
        coinLifetime: 5,
        startingHp: 3
    )
}
