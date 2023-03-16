import SpriteKit

private let startTarget: CGFloat = 50
private let directionTreshold: CGFloat = 20

final class GameGestureRecognizer {
    enum State {
        case waiting
        case possible(CGPoint)
        case registering(CGPoint, [Direction])
        
        var directions: [Direction]? {
            switch self {
            case .registering(_, let d):
                return d
            default:
                return nil
            }
        }
    }
    
    var onRegistered: (() -> Void)?
    var onChangedDirection: (() -> Void)?
    var onEnded: (() -> Void)?
    
    private(set) var state: State = .waiting
    
    weak var scene: SKScene?
    
    func touchBegan(_ touch: UITouch) {
        switch state {
        case .waiting:
            let location = touch.location(in: scene!)
            state = .possible(location)
        default:
            assertionFailure()
        }
    }
    
    func touchMoved(_ touch: UITouch) {
        let location = touch.location(in: scene!)
        switch state {
        case .waiting:
            assertionFailure()
        case .possible(let initialPoint):
            if initialPoint.x + startTarget < location.x {
                state = .registering(location, [.right])
                onRegistered?()
            } else if initialPoint.x - startTarget > location.x {
                state = .registering(location, [.left])
                onRegistered?()
            } else if initialPoint.y + startTarget < location.y {
                state = .registering(location, [.top])
                onRegistered?()
            } else if initialPoint.y - startTarget > location.y {
                state = .registering(location, [.bottom])
                onRegistered?()
            }
        case .registering(let initialPoint, let dirrs):
            var dirs: [(Direction, CGFloat)] = []
            let horizontalShift = abs(initialPoint.x - location.x)
            let verticalShift = abs(initialPoint.y - location.y)
            if horizontalShift > directionTreshold {
                dirs.append((location.x > initialPoint.x ? .right : .left, horizontalShift))
            }
            if verticalShift > directionTreshold {
                dirs.append((location.y > initialPoint.y ? .top : .bottom, verticalShift))
            }
            let sortedDirs = dirs.sorted(by: { $0.1 > $1.1 }).map { $0.0 }
            if !sortedDirs.isEmpty {
                if dirrs != sortedDirs {
                    state = .registering(location, sortedDirs)
                }
                onChangedDirection?()
            }
        }
    }
    
    func touchEnded(_ touch: UITouch) {
        state = .waiting
        onEnded?()
    }
    
    func touchCancelled(_ touch: UITouch) {
        state = .waiting
        onEnded?()
    }
}
