import Foundation

typealias TimeFunction = (Int) -> TimeInterval

func standardForTrace(score: Int) -> TimeInterval {
    if score > 100 {
        return 4.5
    }
    if score > 50 {
        return 4.75
    }
    if score > 30 {
        return 5
    }
    if score > 20 {
        return 6
    }
    return 7
}

func standardForCoin(score: Int) -> TimeInterval {
    if score == 0 {
        return Double.infinity
    }
    if score > 140 {
        return 1.4
    }
    if score > 120 {
        return 1.5
    }
    if score > 100 {
        return 1.6
    }
    if score > 80 {
        return 1.7
    }
    if score > 70 {
        return 2.0
    }
    if score > 50 {
        return 2.5
    }
    if score > 30 {
        return 3.5
    }
    if score > 20 {
        return 4
    }
    if score > 10 {
        return 4.5
    }
    return 5
}

struct Preferences {
    let fieldSize: Size
    let traceFunction: TimeFunction
    let coinFunction: TimeFunction
    let startingHp: Int
    let coin5Chance: Double
    
    static let `default` = Preferences(
        fieldSize: .init(width: 5, height: 5),
        traceFunction: standardForTrace,
        coinFunction: standardForCoin,
        startingHp: 3,
        coin5Chance: 0.05
    )
}
