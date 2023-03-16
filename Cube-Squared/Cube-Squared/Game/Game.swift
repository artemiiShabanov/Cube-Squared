import Foundation
import SpriteKit

enum GameEvent {
    case cubeAppeared(c: Coordinate)
    case cubeMoved(d: Direction, rolling: Bool)
    
    case traceAppeared(c: Coordinate)
    case traceDisappeared(c: Coordinate)
    
    case coinAppeared(c: Coordinate)
    case coinDisappeared(c: Coordinate)
    case coinEaten(c: Coordinate)
}

protocol GameEventDelegate: AnyObject {
    func handle(event: GameEvent)
}

final class Game {
    private var field: Field
    private var cubePosition: Coordinate
    private let preferences: Preferences
    
    private(set) var score: Int = 0
    
    weak var delegate: GameEventDelegate?
    
    init(prefs: Preferences) {
        preferences = prefs
        field = .init(size: prefs.fieldSize)
        cubePosition = .init(x: 0, y: 0)
    }
    
    // MARK: - Logic API
    
    func startGame() {
        field.clean()
        cubePosition = randomCoordinate(excludingTiles: [])!
        delegate?.handle(event: .cubeAppeared(c: cubePosition))
        placeCoin()
    }
    
    @discardableResult
    func moveIfPossible(to dirs: [Direction]) -> Bool {
        for d in dirs {
            if field.hasSpace(from: cubePosition, to: d) {
                moveCube(to: d, rolling: false)
                return true
            }
        }
        return false
    }
    
    @discardableResult
    func rollIfPossible(to dirs: [Direction]) -> Bool {
        for d in dirs {
            let shifted = cubePosition.shifted(to: d)
            if field.has(type: .trace, at: shifted) || field.has(type: .coin, at: shifted) {
                moveCube(to: d, rolling: true)
                return true
            }
        }
        return false
    }
    
    private func moveCube(to d: Direction, rolling: Bool) {
        field.add(type: .trace, at: cubePosition)
        delegate?.handle(event: .traceAppeared(c: cubePosition))
        field.del(type: .cube, at: cubePosition)
        
        cubePosition = cubePosition.shifted(to: d)
        delegate?.handle(event: .cubeMoved(d: d, rolling: rolling))
        field.add(type: .cube, at: cubePosition)
        
        if field.has(type: .coin, at: cubePosition) {
            score += 1
            field.del(type: .coin, at: cubePosition)
            delegate?.handle(event: .coinEaten(c: cubePosition))
            placeCoin()
        }
    }
    
    // MARK: - Game cicle API
    
    func expiredTrace(at c: Coordinate) {
        assert(field.has(type: .trace, at: c))
        field.del(type: .trace, at: c)
        delegate?.handle(event: .traceDisappeared(c: c))
    }
    
    func expiredCoin(at c: Coordinate) {
        assert(field.has(type: .coin, at: c))
        field.del(type: .coin, at: c)
        delegate?.handle(event: .coinDisappeared(c: c))
        
        score -= 1
        placeCoin()
    }
    
}

// MARK: - Current mode

extension Game {
    var traceLifetime: TimeInterval {
        preferences.traceLifetime
    }
    
    var coinLifetime: TimeInterval {
        preferences.coinLifetime
    }
}

// MARK: - Tile events

private extension Game {
    func randomCoordinate(excludingTiles: Set<TileType>) -> Coordinate? {
        field.availableSpace(ignoring: excludingTiles).randomElement()
    }
    
    func placeCoin() {
        guard let c = randomCoordinate(excludingTiles: [.cube]) else {
            return
        }
        field.add(type: .coin, at: c)
        delegate?.handle(event: .coinAppeared(c: c))
    }
}
