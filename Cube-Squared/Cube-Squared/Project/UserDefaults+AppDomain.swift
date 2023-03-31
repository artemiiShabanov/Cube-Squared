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
    
    var seenOnboarding: Bool {
        get {
            bool(forKey: "seen_onboarding")
        }
        set {
            set(newValue, forKey: "seen_onboarding")
        }
    }
}
