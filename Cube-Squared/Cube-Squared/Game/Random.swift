enum Random {
    static func bool(with chance: Double) -> Bool {
        Double.random(in: 0...1) < chance
    }
}
