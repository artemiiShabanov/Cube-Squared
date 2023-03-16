import UIKit

var greeting = "Hello, playground"

enum TileType: Int {
    case coin = 0
    case trace
    case cube
    
    fileprivate var val: Int {
        return 1 << rawValue
    }
}

struct Tile: Hashable {
    private var val: Int
    
    init(type: TileType? = nil) {
        self.val = type?.val ?? 0
    }
    
    func has(_ type: TileType) -> Bool {
        val & type.val != 0
    }
    
    mutating func add(_ type: TileType) {
        val += type.val
    }
    
    mutating func del(_ type: TileType) {
        val -= type.val
    }
}

var e = Tile(type: nil)
let c = Tile(type: .coin)
let t = Tile(type: .trace)
let cu = Tile(type: .cube)

()

print(e.has(.trace))
print(e.has(.cube))
print(cu.has(.cube))

e.add(.cube)
print(e.has(.cube))

e.add(.trace)
print(e.has(.trace))

e.del(.cube)
print(e.has(.cube))
