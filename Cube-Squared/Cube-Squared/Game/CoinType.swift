import UIKit

enum CoinType: CaseIterable {
    case simple
    case x5
    case hp
    
    var asset: String {
        switch self {
        case .simple:
            return Assets.coin
        case .x5:
            return Assets.coin5
        case .hp:
            return Assets.hp_coin
        }
    }
    
    var color: UIColor {
        switch self {
        case .simple:
            return Colors.coin
        case .x5:
            return Colors.coin5
        case .hp:
            return Colors.cube
        }
    }
    
    var tile: TileType {
        switch self {
        case .simple:
            return .coin
        case .x5:
            return .coin5
        case .hp:
            return .hp
        }
    }
}
