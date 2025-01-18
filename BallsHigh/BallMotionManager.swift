import CoreMotion
import SwiftUI

class BallMotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var shakeCount: Int = 0
    @Published var tiltDirection: TiltDirection = .none
    
    private var lastShakeTime = Date()
    private let shakeCooldown: TimeInterval = 0.5
    
    func startMotionUpdates() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
                guard let data = data else { return }
                
                // Detect shake
                let acceleration = data.acceleration
                let totalAcceleration = sqrt(
                    acceleration.x * acceleration.x +
                    acceleration.y * acceleration.y +
                    acceleration.z * acceleration.z
                )
                
                if totalAcceleration > 2.0 {
                    let now = Date()
                    if now.timeIntervalSince(self?.lastShakeTime ?? Date()) > self?.shakeCooldown ?? 0.5 {
                        self?.shakeCount += 1
                        self?.lastShakeTime = now
                    }
                }
                
                // Detect tilt
                if abs(acceleration.x) > 0.5 {
                    self?.tiltDirection = acceleration.x > 0 ? .right : .left
                } else {
                    self?.tiltDirection = .none
                }
            }
        }
    }
    
    func stopMotionUpdates() {
        motionManager.stopAccelerometerUpdates()
    }
    
    func simulateShake() {
        shakeCount += 1
    }
} 