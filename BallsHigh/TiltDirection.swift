enum TiltDirection {
    case none
    case left
    case right
    
    // Add helper for threshold detection
    static func from(acceleration: Double) -> TiltDirection {
        let threshold = 0.5
        if acceleration > threshold {
            return .right
        } else if acceleration < -threshold {
            return .left
        }
        return .none
    }
} 