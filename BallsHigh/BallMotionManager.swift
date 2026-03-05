import CoreMotion
import SwiftUI

class BallMotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var shakeCount: Int = 0
    @Published var tiltDirection: TiltDirection = .none
    @Published var isUpright: Bool = false

    private var lastShakeTime = Date()
    private let shakeCooldown: TimeInterval = 0.5

    func startMotionUpdates() {
        guard motionManager.isAccelerometerAvailable else { return }

        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self, let data else { return }

            let acceleration = data.acceleration
            let totalAcceleration = sqrt(
                acceleration.x * acceleration.x +
                acceleration.y * acceleration.y +
                acceleration.z * acceleration.z
            )

            // Detect shake
            if totalAcceleration > 2.0 {
                let now = Date()
                if now.timeIntervalSince(self.lastShakeTime) > self.shakeCooldown {
                    self.shakeCount += 1
                    self.lastShakeTime = now
                }
            }

            // Detect tilt
            if abs(acceleration.x) > 0.5 {
                self.tiltDirection = acceleration.x > 0 ? .right : .left
            } else {
                self.tiltDirection = .none
            }

            // Detect upright (phone held vertically, screen facing user)
            self.isUpright = acceleration.y < -0.8
        }
    }

    func stopMotionUpdates() {
        motionManager.stopAccelerometerUpdates()
    }

    func simulateShake() {
        shakeCount += 1
    }
}
