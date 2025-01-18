import CoreMotion
import SwiftUI

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private var timer: Timer?
    
    @Published var shakeCount = 0
    @Published var tiltDirection: TiltDirection = .none
    
    enum TiltDirection {
        case none
        case left
        case right
    }
    
    func startMotionUpdates() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
                guard let data = data else { return }
                
                // Detect shake
                if abs(data.acceleration.x) > 2.0 || 
                   abs(data.acceleration.y) > 2.0 || 
                   abs(data.acceleration.z) > 2.0 {
                    self?.shakeCount += 1
                }
                
                // Detect tilt
                if data.acceleration.x > 0.5 {
                    self?.tiltDirection = .right
                } else if data.acceleration.x < -0.5 {
                    self?.tiltDirection = .left
                } else {
                    self?.tiltDirection = .none
                }
            }
        }
    }
    
    func stopMotionUpdates() {
        motionManager.stopAccelerometerUpdates()
    }
} 