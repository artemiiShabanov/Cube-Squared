import Foundation

typealias TimeFunction = (Int) -> TimeInterval

func standardForTrace(score: Int) -> TimeInterval {
    if score > 100 {
        return 5
    }
    if score > 50 {
        return 5.25
    }
    if score > 30 {
        return 5.5
    }
    if score > 20 {
        return 6
    }
    return 7
}

func standardForCoin(score: Int) -> TimeInterval {
    let checkpoints = [
        (0, Double.infinity),
        (1, 5),
        (20, 4),
        (50, 3.5),
        (90, 2.7),
        (140, 2.1),
        (200, 1.4),
        (300, 1.2)
    ]
    
    var prev: (Int, Double)?
    for checkpoint in checkpoints {
        let upScore = checkpoint.0
        let time = checkpoint.1
        
        if score <= upScore {
            if let prev {
                let prevScore = prev.0
                let prevTime = prev.1
                
                let multiplicator = 1 - Double(score - prevScore) / Double(upScore - prevScore)
                if multiplicator == 0 {
                    return time
                } else {
                    return time + (prevTime - time) * multiplicator
                }
            } else {
                return time
            }
        }
        
        prev = checkpoint
    }
    
    return checkpoints.last!.1
}

struct Preferences {
    let fieldSize: Size
    let traceFunction: TimeFunction
    let coinFunction: TimeFunction
    let startingHp: Int
    let coin5Chance: Double
    let hpChance: Double
    
    static let `default` = Preferences(
        fieldSize: .init(width: 5, height: 5),
        traceFunction: standardForTrace,
        coinFunction: standardForCoin,
        startingHp: 3,
        coin5Chance: 0.05,
        hpChance: 0.03
    )
}
