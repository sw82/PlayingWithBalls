import AVFoundation
import SwiftUI

class MicrophoneMonitor: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var lastClapTime: Date = Date()
    private var clapCooldown: TimeInterval = 0.3
    
    @Published var blowDetected = false
    @Published var blowStrength: Double = 0
    @Published var clapDetected = false
    
    func startMonitoring() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.requestRecordPermission { [weak self] allowed in
                guard allowed else { return }
                
                DispatchQueue.main.async {
                    self?.setupAudioRecording()
                }
            }
        } catch {
            print("Failed to request microphone permission: \(error)")
        }
    }
    
    private func setupAudioRecording() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let url = URL(fileURLWithPath: "/dev/null", isDirectory: true)
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatAppleLossless),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.audioRecorder?.updateMeters()
                let level = self?.audioRecorder?.averagePower(forChannel: 0) ?? -160
                
                // Detect blow strength
                if level > -30 {
                    self?.blowStrength = Double(level + 160) / 160.0 // Normalize to 0-1
                    self?.blowDetected = true
                } else {
                    self?.blowStrength = 0
                    self?.blowDetected = false
                }
                
                // Detect claps (sharp, loud sounds)
                if level > -10 {
                    let currentTime = Date()
                    if let self = self, 
                       currentTime.timeIntervalSince(self.lastClapTime) > self.clapCooldown {
                        self.lastClapTime = currentTime
                        self.clapDetected = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            self.clapDetected = false
                        }
                    }
                }
            }
        } catch {
            print("Failed to set up audio monitoring: \(error)")
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        audioRecorder?.stop()
        audioRecorder = nil
        
        try? AVAudioSession.sharedInstance().setActive(false)
    }
} 