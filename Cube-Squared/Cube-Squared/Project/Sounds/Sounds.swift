import SpriteKit

enum SoundFX {
    static let rollSound = SKAction.playSoundFileNamed("roll.wav", waitForCompletion: false)
    static let coinSound = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false)
    static let errorSound = SKAction.playSoundFileNamed("error.wav", waitForCompletion: false)
}
