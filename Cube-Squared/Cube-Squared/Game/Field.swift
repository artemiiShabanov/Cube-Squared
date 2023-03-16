import Foundation

enum TileType: Int, CaseIterable {
    case coin = 0
    case trace
    case cube
    
    fileprivate var val: Int {
        return 1 << rawValue
    }
}

fileprivate struct Tile: Hashable, CustomStringConvertible {
    private var val: Int
    
    init(type: TileType? = nil) {
        self.val = type?.val ?? 0
    }
    
    var isEmpty: Bool {
        val == 0
    }
    
    func has(_ type: TileType) -> Bool {
        val & type.val != 0
    }
    
    mutating func add(_ type: TileType) {
        guard !has(type) else { return }
        val += type.val
    }
    
    mutating func del(_ type: TileType) {
        guard has(type) else { return }
        val -= type.val
    }
    
    var description: String {
        TileType.allCases.compactMap { has($0) ? String($0.val) : nil }.joined(separator: "+")
    }
}

struct Field {
    private var tiles: [[Tile]]
    private let size: Size
    
    init(size: Size) {
        self.size = size
        self.tiles = Array(repeating: Array(repeating: .init(), count: size.width), count: size.height)
    }
    
    func has(type: TileType, at c: Coordinate) -> Bool {
        guard check(coordinate: c) else {
            return false
        }
        return tiles[c.x][c.y].has(type)
    }
    
    mutating func add(type: TileType, at c: Coordinate) {
        guard check(coordinate: c) else {
            assertionFailure()
            return
        }
        tiles[c.x][c.y].add(type)
    }
    
    mutating func del(type: TileType, at c: Coordinate) {
        guard check(coordinate: c) else {
            assertionFailure()
            return
        }
        tiles[c.x][c.y].del(type)
    }
    
    mutating func clean() {
        tiles = Array(repeating: Array(repeating: .init(), count: size.width), count: size.height)
    }
}

// MARK: - Space operations

extension Field {
    func hasSpace(from c: Coordinate, to d: Direction) -> Bool {
        check(coordinate: c.shifted(to: d))
    }
    
    func availableSpace(ignoring: Set<TileType>) -> Set<Coordinate> {
        var res = Set<Coordinate>()
        
        for i in 0..<size.width {
            for j in 0..<size.height {
                if !ignoring.contains(where: { tiles[i][j].has($0) }) {
                    res.insert(.init(x: i, y: j))
                }
            }
        }
        
        return res
    }
}

// MARK: - Private

private extension Field {
    func check(coordinate c: Coordinate) -> Bool {
        c.x < size.width &&
        c.x >= 0 &&
        c.y < size.height &&
        c.y >= 0
    }
}
