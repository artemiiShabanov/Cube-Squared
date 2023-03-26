import Foundation
import SpriteKit

enum GameEvent {
    case cubeAppeared(c: Coordinate)
    case cubeMoved(d: Direction, rolling: Bool)
    
    case traceAppeared(c: Coordinate)
    case traceDisappeared(c: Coordinate)
    
    case coinAppeared(c: Coordinate, type: CoinType)
    case coinDisappeared(c: Coordinate)
    case coinEaten(c: Coordinate)
    
    case scoreChanged(new: Int)
    case hpChanged(new: Int)
    
    case gameOver
}

protocol GameEventDelegate: AnyObject {
    func handle(event: GameEvent)
}

final class Game {
    private var field: Field
    private var cubePosition: Coordinate
    private var lostHP = false
    private let preferences: Preferences
    
    private(set) var score: Int = 0 {
        didSet {
            delegate?.handle(event: .scoreChanged(new: score))
            lostHP = false
        }
    }
    private(set) var hp: Int = 0 {
        didSet {
            delegate?.handle(event: .hpChanged(new: hp))
        }
    }
    
    weak var delegate: GameEventDelegate?
    
    init(prefs: Preferences) {
        preferences = prefs
        field = .init(size: prefs.fieldSize)
        cubePosition = .init(x: 0, y: 0)
    }
    
    // MARK: - Logic API
    
    func startGame() {
        field.clean()
        
        score = 0
        hp = preferences.startingHp
        
        cubePosition = randomCoordinate(excludingTiles: [])!
        field.add(type: .cube, at: cubePosition)
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
            if field.has(anyOf: [.trace] + CoinType.allCases.map(\.tile), at: shifted) {
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
        } else if field.has(type: .coin5, at: cubePosition) {
            score += 5
            field.del(type: .coin5, at: cubePosition)
            delegate?.handle(event: .coinEaten(c: cubePosition))
            placeCoin()
        } else if field.has(type: .hp, at: cubePosition) {
            score += 1
            hp += 1
            field.del(type: .hp, at: cubePosition)
            delegate?.handle(event: .coinEaten(c: cubePosition))
            placeCoin()
        }
    }
    
    // MARK: - Game cycle API
    
    func expiredTrace(at c: Coordinate) {
        assert(field.has(type: .trace, at: c))
        field.del(type: .trace, at: c)
        delegate?.handle(event: .traceDisappeared(c: c))
    }
    
    func expiredCoin(at c: Coordinate) {
        let coinTilesTypes = CoinType.allCases.map(\.tile)
        assert(field.has(anyOf: coinTilesTypes, at: c))
        coinTilesTypes.forEach { field.del(type: $0, at: c) }
        delegate?.handle(event: .coinDisappeared(c: c))
        
        hp -= 1
        if hp > 0 {
            lostHP = true
            placeCoin()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: { [weak self] in
                self?.delegate?.handle(event: .gameOver)
            })
        }
    }
    
}

// MARK: - Current mode

extension Game {
    var traceLifetime: TimeInterval {
        preferences.traceFunction(score)
    }
    
    var coinLifetime: TimeInterval {
        if lostHP {
            return Double.infinity
        }
        return preferences.coinFunction(score)
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
        
        let isHP = (hp < preferences.startingHp) && Random.bool(with: preferences.hpChance)
        let is5 = Random.bool(with: preferences.coin5Chance)
        
        let coinType: CoinType = isHP ? .hp : is5 ? .x5 : .simple
        
        field.add(type: coinType.tile, at: c)
        delegate?.handle(event: .coinAppeared(c: c, type: coinType))
    }
}
