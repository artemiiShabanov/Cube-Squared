import UIKit

func standardForCoin(score: Int) -> TimeInterval {
    let checkpoints = [
        (0, Double.infinity),
        (1, 5),
        (50, 4),
        (100, 3.5),
        (150, 2.7),
        (200, 2.1),
        (300, 1.4),
        (500, 1.2)
    ]
    
    var prev: (Int, Double)?
    for el in checkpoints {
        let upScore = el.0
        let time = el.1
        
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
        
        prev = el
    }
    
    return checkpoints.last!.1
}

var prev = Double.infinity
for i in stride(from: 0, to: 650, by: 10) {
    let x = standardForCoin(score: i)
    print(i, " ", x)
    if x > prev {
        fatalError()
    }
    prev = x
}
