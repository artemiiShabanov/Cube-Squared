import Foundation

extension UserDefaults {
    var maxScore: Int {
        get {
            integer(forKey: "max_score")
        }
        set {
            set(newValue, forKey: "max_score")
        }
    }
}
