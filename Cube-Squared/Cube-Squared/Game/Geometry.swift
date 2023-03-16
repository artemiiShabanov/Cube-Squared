import Foundation

enum Direction {
    case top
    case bottom
    case left
    case right
    
    var coordinateShift: Coordinate {
        switch self {
        case .top:
            return .init(x: 0, y: 1)
        case .bottom:
            return .init(x: 0, y: -1)
        case .left:
            return .init(x: -1, y: 0)
        case .right:
            return .init(x: 1, y: 0)
        }
    }
}

struct Coordinate: Hashable {
    let x: Int
    let y: Int
    
    func shifted(to d: Direction) -> Coordinate {
        .init(x: x + d.coordinateShift.x, y: y + d.coordinateShift.y)
    }
}

struct Size {
    let width: Int
    let height: Int
}
