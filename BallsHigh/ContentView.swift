//
//  ContentView.swift
//  BallsHigh
//
//  Created by sebastian winkler on 26.12.24.
//

import SwiftUI

struct Ball: Identifiable {
    let id = UUID()
    var position: CGPoint
    var color: Color = .yellow
    var pressCount: Int = 0
    var isActive: Bool = true
    var alignment: BallAlignment = .none
    var scale: CGFloat = 1.0
}

enum BallAlignment {
    case none
    case vertical
    case horizontal
}

struct ContentView: View {
    @State private var scene = 1
    @State private var balls: [Ball] = [
        Ball(position: CGPoint(x: UIScreen.main.bounds.width/3, 
             y: UIScreen.main.bounds.height/2))
    ]
    @State private var lastRubbedBallId: UUID?
    @State private var pressCount: Int = 0
    @State private var backgroundColor: Color = .white
    @State private var changedBallPositions: Set<UUID> = []
    @State private var wrongBallsPressed: Set<UUID> = []
    @State private var hasCompletedOnce = false
    @State private var clapCount: Int = 0
    @State private var deviceOrientation: UIDeviceOrientation = .unknown
    @StateObject private var motionManager = BallMotionManager()
    @StateObject private var microphoneMonitor = MicrophoneMonitor()
    @State private var scene13Configuration: [Ball] = []
    
    var instructionText: String {
        switch scene {
        case 1:
            return "Press the yellow ball"
        case 2:
            return "Press the yellow ball again"
        case 3:
            return "Gently rub your finger over the yellow ball"
        case 4:
            return "Now gently rub your finger over another yellow ball"
        case 5:
            return "Now press 5 times the yellow ball"
        case 6:
            return "Now press 5 times the red ball"
        case 7:
            return "Now press 5 times the blue ball"
        case 8:
            return "Now shake the phone a bit"
        case 9:
            return "Now shake it even more"
        case 10:
            return "Try to tilt the phone to the left side"
        case 11:
            return "Try to tilt the phone to the right side"
        case 12:
            return "Shake the phone to distribute them again"
        case 13:
            return "Press on all yellow balls"
        case 14:
            return "Funny, turn it on the lights again and by pressing on all yellow balls again"
        case 15:
            return "Two balls are not in the right position. Do you know which?"
        case 16:
            return "Shake it again"
        case 17:
            return "Blow a bit"
        case 18:
            return "Blow a bit stronger"
        case 19:
            return "Hold the phone upright so the balls can sink again"
        case 20:
            return "Clap in your hands"
        case 21:
            return "Blow a bit"
        case 22:
            return "Clap twice"
        case 23:
            return "Clap three times"
        case 24:
            return "Clap again"
        case 25:
            return "Applause"
        case 26:
            return "More applause"
        case 27:
            return "Oh no. Too much. Press the white ball"
        case 28:
            return "Congratulations! Press the yellow ball to start over"
        default:
            return ""
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                VStack {
                    #if DEBUG
                    // Debug Scene Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(1...27, id: \.self) { sceneNumber in
                                Button(action: {
                                    setupScene(sceneNumber)
                                }) {
                                    Text("\(sceneNumber)")
                                        .padding(8)
                                        .background(scene == sceneNumber ? Color.blue : Color.gray)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 50)
                    .background(Color.black.opacity(0.1))
                    #endif
                    
                    Text(instructionText)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(backgroundColor == .black ? .white : .black)
                        .padding()
                        .multilineTextAlignment(.center)
                    
                    if scene >= 5 && scene <= 7 {
                        Text("Pressed: \(pressCount)/5")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    #if DEBUG
                    // Debug controls for simulator
                    HStack {
                        Button(action: {
                            motionManager.simulateShake()
                        }) {
                            Text("Shake")
                                .padding(8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        Button(action: {
                            handleTilt(direction: .left)
                        }) {
                            Text("Tilt Left")
                                .padding(8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        Button(action: {
                            handleTilt(direction: .right)
                        }) {
                            Text("Tilt Right")
                                .padding(8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        Button(action: {
                            handleBlow()
                        }) {
                            Text("Blow")
                                .padding(8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        Button(action: {
                            deviceOrientation = .portrait
                            handleDeviceOrientation()
                        }) {
                            Text("Hold Upright")
                                .padding(8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.bottom, 20)
                    #endif
                }
                
                ForEach(balls) { ball in
                    BallView(
                        ball: ball, 
                        scene: scene,
                        onTap: { handleTap(ballId: ball.id) },
                        onRub: { handleRub(ballId: ball.id) }
                    )
                }
            }
            .onAppear {
                if let firstBall = balls.first {
                    balls[0].position = CGPoint(
                        x: geometry.size.width/3,
                        y: geometry.size.height/2
                    )
                }
                motionManager.startMotionUpdates()
                microphoneMonitor.startMonitoring()
                
                UIDevice.current.beginGeneratingDeviceOrientationNotifications()
                NotificationCenter.default.addObserver(
                    forName: UIDevice.orientationDidChangeNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    deviceOrientation = UIDevice.current.orientation
                    handleDeviceOrientation()
                }
            }
            .onDisappear {
                motionManager.stopMotionUpdates()
                microphoneMonitor.stopMonitoring()
                NotificationCenter.default.removeObserver(self)
                UIDevice.current.endGeneratingDeviceOrientationNotifications()
                resetGame()
            }
            .onChange(of: motionManager.shakeCount) { _, _ in
                handleShake()
            }
            .onChange(of: motionManager.tiltDirection) { _, newDirection in
                handleTilt(direction: newDirection)
            }
            .onChange(of: microphoneMonitor.blowDetected) { _, detected in
                if detected {
                    handleBlow()
                }
            }
            .onChange(of: scene) { _, newScene in
                if newScene == 14 {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        backgroundColor = .black
                        balls.forEach { ball in
                            if let idx = balls.firstIndex(where: { $0.id == ball.id }) {
                                balls[idx].isActive = ball.color == .yellow
                            }
                        }
                    }
                }
            }
            .onChange(of: microphoneMonitor.clapDetected) { _, detected in
                if detected {
                    handleClap()
                }
            }
        }
    }
    
    private func setupInitialScene(geometry: GeometryProxy) {
        balls = []
        for _ in 0..<15 {
            balls.append(Ball(position: randomPosition(), color: .yellow))
        }
        arrangeInGrid()
        
        backgroundColor = .black
        balls.forEach { ball in
            if let idx = balls.firstIndex(where: { $0.id == ball.id }) {
                balls[idx].isActive = ball.color == .yellow
            }
        }
    }
    
    private func handleTap(ballId: UUID) {
        guard let index = balls.firstIndex(where: { $0.id == ballId }) else { return }
        let ball = balls[index]
        
        switch scene {
        case 1, 2:
            if ball.color == .yellow && ball.isActive {
                let spacing: CGFloat = 100
                let newPosition = CGPoint(
                    x: (balls.last?.position.x ?? 0) + spacing,
                    y: ball.position.y
                )
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    balls.append(Ball(position: newPosition))
                    scene += 1
                }
            }
            
        case 3, 4: // Rubbing scenes handled separately
            break
            
        case 5...7: // Press 5 times scenes
            handleFivePressScene(ball: ball, index: index)
            
        case 13: // Store complete grid configuration
            if ball.color == .yellow && ball.isActive {
                withAnimation {
                    balls[index].isActive = false
                    if !balls.contains(where: { $0.color == .yellow && $0.isActive }) {
                        // Store the COMPLETE configuration before moving to scene 14
                        scene13Configuration = balls.map { ball in
                            Ball(position: ball.position,
                                 color: ball.color,
                                 pressCount: ball.pressCount,
                                 isActive: true,
                                 alignment: ball.alignment,
                                 scale: ball.scale)
                        }
                        // For scene 14, hide non-yellow balls
                        withAnimation {
                            balls.indices.forEach { i in
                                balls[i].isActive = balls[i].color == .yellow
                            }
                            backgroundColor = .black
                            scene = 14
                        }
                    }
                }
            }
            
        case 14: // Turn lights on again
            if ball.color == .yellow && ball.isActive {
                withAnimation {
                    balls[index].isActive = false
                    if !balls.contains(where: { $0.color == .yellow && $0.isActive }) {
                        // Restore scene 13 configuration and prepare for scene 15
                        backgroundColor = .white
                        prepareChangedBallsForScene15()
                        scene = 15
                    }
                }
            }
            
        case 15: // Find changed balls
            if changedBallPositions.contains(ballId) {
                withAnimation {
                    wrongBallsPressed.insert(ballId)
                    if wrongBallsPressed == changedBallPositions {
                        // Restore original scene 13 configuration but with black background
                        balls = scene13Configuration.map { ball in
                            Ball(position: ball.position,
                                 color: ball.color,
                                 pressCount: ball.pressCount,
                                 isActive: true,
                                 alignment: ball.alignment,
                                 scale: ball.scale)
                        }
                        backgroundColor = .black
                        scene = 16
                    }
                }
            }
            
        case 27: // Press white ball to restart
            if ball.color == .white {
                withAnimation {
                    scene = 28
                    hasCompletedOnce = true
                }
            }
            
        case 28: // Start over
            if ball.color == .yellow {
                withAnimation {
                    scene = 1
                    resetGame()
                }
            }
            
        default:
            break
        }
    }
    
    private func handleRub(ballId: UUID) {
        guard scene == 3 || scene == 4 else { return }
        guard let index = balls.firstIndex(where: { $0.id == ballId }) else { return }
        guard balls[index].isActive else { return }
        
        if scene == 3 {
            if balls[index].color == .yellow {
                withAnimation {
                    balls[index].color = .red
                    lastRubbedBallId = ballId
                    scene = 4
                }
            }
        } else if scene == 4 && ballId != lastRubbedBallId {
            if balls[index].color == .yellow {
                withAnimation {
                    balls[index].color = .blue
                    scene = 5
                }
            }
        }
    }
    
    private func handleFivePressScene(ball: Ball, index: Int) {
        if ball.isActive {
            let correctColor: Color
            let nextScene: Int
            
            switch scene {
            case 5:
                correctColor = .yellow
                nextScene = 6
            case 6:
                correctColor = .red
                nextScene = 7
            case 7:
                correctColor = .blue
                nextScene = 8
            default:
                return
            }
            
            if ball.color == correctColor {
                withAnimation {
                    pressCount += 1
                    if pressCount == 5 {
                        createFiveBalls(fromBallId: ball.id, color: correctColor, alignment: .vertical)
                        scene = nextScene
                        pressCount = 0
                    }
                }
            }
        }
    }
    
    private func createFiveBalls(fromBallId: UUID, color: Color, alignment: BallAlignment) {
        guard let index = balls.firstIndex(where: { $0.id == fromBallId }) else { return }
        let originalBall = balls[index]
        
        let spacing: CGFloat = 70
        var newBalls: [Ball] = []
        
        for i in 0..<5 {
            let newPosition: CGPoint
            if alignment == .vertical {
                newPosition = CGPoint(
                    x: originalBall.position.x,
                    y: originalBall.position.y - spacing * 2 + spacing * CGFloat(i)
                )
            } else {
                newPosition = CGPoint(
                    x: originalBall.position.x - spacing * 2 + spacing * CGFloat(i),
                    y: originalBall.position.y
                )
            }
            
            newBalls.append(Ball(
                position: newPosition,
                color: color,
                alignment: alignment
            ))
        }
        
        balls.remove(at: index)
        balls.append(contentsOf: newBalls)
    }
    
    private func handleShake() {
        switch scene {
        case 8: // Slight misalignment
            withAnimation(.spring()) {
                for i in 0..<balls.count {
                    let randomOffset = CGPoint(
                        x: CGFloat.random(in: -20...20),
                        y: CGFloat.random(in: -20...20)
                    )
                    balls[i].position.x += randomOffset.x
                    balls[i].position.y += randomOffset.y
                }
                scene = 9
            }
            
        case 9: // Wild distribution
            withAnimation(.spring()) {
                for i in 0..<balls.count {
                    balls[i].position = randomPosition()
                }
                scene = 10
            }
            
        case 12: // Grid arrangement
            withAnimation(.spring()) {
                arrangeInGrid()
                scene = 13
            }
            
        case 16: // Restore grid then transition to circle
            withAnimation(.spring()) {
                arrangeInGrid()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring()) {
                        // Randomly mix colors before arranging in circle
                        balls.indices.forEach { i in
                            if CGFloat.random(in: 0...1) > 0.5 {
                                balls[i].color = [Color.yellow, .red, .blue].randomElement() ?? .yellow
                            }
                        }
                        arrangeInCircle()
                        scene = 17
                    }
                }
            }
            
        case 1...7, 10, 11, 13...15, 17...27:  // Add all other possible scenes
            break
            
        default:  // Handle any future cases
            break
        }
    }
    
    private func handleBlow() {
        switch scene {
        case 17: // First gentle blow - random distribution upward
            withAnimation(.spring()) {
                for i in 0..<balls.count {
                    // Random upward movement with some horizontal scatter
                    let randomHorizontalOffset = CGFloat.random(in: -50...50)
                    balls[i].position.y -= 50 // Move up
                    balls[i].position.x += randomHorizontalOffset
                }
                fadeBackground(amount: 0.3)
                scene = 18
            }
            
        case 18: // Stronger blow - balls almost out of sight
            withAnimation(.spring()) {
                for i in 0..<balls.count {
                    // More dramatic upward movement with wider scatter
                    let randomHorizontalOffset = CGFloat.random(in: -100...100)
                    // Move most balls almost out of sight, with some variation
                    let randomUpwardOffset = UIScreen.main.bounds.height * CGFloat.random(in: 0.6...0.9)
                    balls[i].position.y -= randomUpwardOffset
                    balls[i].position.x += randomHorizontalOffset
                }
                fadeBackground(amount: 0.8)
                scene = 19
            }
            
        case 21: // Final blow
            withAnimation(.spring()) {
                for i in 0..<balls.count {
                    balls[i].scale *= 1.2
                }
                scene = 22
            }
            
        default:
            break
        }
    }
    
    private func handleClap() {
        switch scene {
        case 20: // First clap - just make balls bigger
            withAnimation(.spring()) {
                for i in 0..<balls.count {
                    balls[i].scale *= 1.5  // Just increase size
                }
                scene = 21
            }
            
        case 21: // Double clap - bigger + overlap
            withAnimation(.spring()) {
                for i in 0..<balls.count {
                    balls[i].scale *= 2.0
                    // Add slight overlap effect
                    let randomOffset = CGPoint(
                        x: CGFloat.random(in: -30...30),
                        y: CGFloat.random(in: -30...30)
                    )
                    balls[i].position.x += randomOffset.x
                    balls[i].position.y += randomOffset.y
                }
                scene = 22
            }
            
        case 22: // Triple clap
            withAnimation(.spring()) {
                for i in 0..<balls.count {
                    balls[i].scale *= 2.0
                }
                scene = 23
            }
            
        case 23: // Single clap again
            withAnimation(.spring()) {
                for i in 0..<balls.count {
                    balls[i].scale *= 2.5
                }
                scene = 24
            }
            
        case 24: // Single clap again
            withAnimation(.spring()) {
                for i in 0..<balls.count {
                    balls[i].scale *= 2.5
                }
                scene = 25
            }
            
        case 25, 26: // Applause
            withAnimation(.spring()) {
                for i in 0..<balls.count {
                    balls[i].scale *= 3.0
                }
                if scene == 25 {
                    scene = 26
                } else {
                    createFinalScene()
                }
            }
            
        default:
            break
        }
    }
    
    private func handleDeviceOrientation() {
        if scene == 19 {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                // Let balls fall back randomly on screen with a more natural distribution
                for i in 0..<balls.count {
                    let randomDelay = Double.random(in: 0...0.3)
                    DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
                        withAnimation(.spring()) {
                            balls[i].position = CGPoint(
                                x: CGFloat.random(in: 50...(UIScreen.main.bounds.width - 50)),
                                y: CGFloat.random(in: UIScreen.main.bounds.height * 0.3...UIScreen.main.bounds.height * 0.8)
                            )
                        }
                    }
                }
                backgroundColor = .white // Reset background
                scene = 20
            }
        }
    }
    
    private func handleTilt(direction: TiltDirection) {
        switch scene {
        case 10:
            if direction == .left {
                moveBallsToSide(direction)
                scene = 11
            }
        case 11:
            if direction == .right {
                moveBallsToSide(direction)
                scene = 12
            }
        default:
            break
        }
    }
    
    private func moveBallsToSide(_ side: TiltDirection) {
        withAnimation(.spring()) {
            for i in 0..<balls.count {
                switch side {
                case .left:
                    balls[i].position.x = 50 + CGFloat.random(in: 0...50)
                case .right:
                    balls[i].position.x = UIScreen.main.bounds.width - 100 + CGFloat.random(in: 0...50)
                case .none:
                    break  // Add this case to handle .none
                }
            }
        }
    }
    
    private func randomPosition() -> CGPoint {
        CGPoint(
            x: CGFloat.random(in: 50...(UIScreen.main.bounds.width - 50)),
            y: CGFloat.random(in: 100...(UIScreen.main.bounds.height - 100))
        )
    }
    
    private func resetGame() {
        withAnimation {
            balls = [Ball(position: CGPoint(x: UIScreen.main.bounds.width/3, 
                                          y: UIScreen.main.bounds.height/2))]
            backgroundColor = .white
            pressCount = 0
            changedBallPositions.removeAll()
            wrongBallsPressed.removeAll()
            clapCount = 0
            lastRubbedBallId = nil
            hasCompletedOnce = false
            balls.forEach { ball in
                if let idx = balls.firstIndex(where: { $0.id == ball.id }) {
                    balls[idx].scale = 1.0
                    balls[idx].isActive = true
                    balls[idx].color = .yellow
                }
            }
        }
    }
    
    private func createFinalScene() {
        withAnimation(.spring()) {
            let centerX = UIScreen.main.bounds.width/2
            let centerY = UIScreen.main.bounds.height/2
            
            balls = [
                Ball(position: CGPoint(x: centerX, y: centerY),
                     color: .yellow,
                     scale: 5.0),
                Ball(position: CGPoint(x: centerX, y: centerY),
                     color: .white,
                     scale: 0.5)
            ]
            scene = 27
        }
    }
    
    private func moveAllBallsUp(amount: CGFloat) {
        withAnimation(.spring()) {
            for i in 0..<balls.count {
                balls[i].position.y -= amount
            }
        }
    }
    
    private func fadeBackground(amount: Double) {
        withAnimation(.easeInOut) {
            backgroundColor = backgroundColor == .black ? 
                .black.opacity(1 - amount) : 
                .white.opacity(1 - amount)
        }
    }
    
    private func arrangeInGrid() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        let columns = 5
        let rows = 3
        let spacing: CGFloat = 70
        
        let startX = (screenWidth - (CGFloat(columns - 1) * spacing)) / 2
        let startY = (screenHeight - (CGFloat(rows - 1) * spacing)) / 2
        
        var positions: [CGPoint] = []
        for row in 0..<rows {
            for col in 0..<columns {
                let x = startX + CGFloat(col) * spacing
                let y = startY + CGFloat(row) * spacing
                positions.append(CGPoint(x: x, y: y))
            }
        }
        
        positions.shuffle()
        
        withAnimation(.spring()) {
            for (index, ball) in balls.enumerated() {
                if index < positions.count {
                    if let ballIndex = balls.firstIndex(where: { $0.id == ball.id }) {
                        balls[ballIndex].position = positions[index]
                    }
                }
            }
        }
    }
    
    private func arrangeInCircle() {
        let centerX = UIScreen.main.bounds.width/2
        let centerY = UIScreen.main.bounds.height/2
        let radius = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)/3
        
        withAnimation(.spring()) {
            for (index, ball) in balls.enumerated() {
                let angle = (2.0 * .pi * Double(index)) / Double(balls.count)
                let x = centerX + radius * cos(angle)
                let y = centerY + radius * sin(angle)
                
                if let ballIndex = balls.firstIndex(where: { $0.id == ball.id }) {
                    balls[ballIndex].position = CGPoint(x: x, y: y)
                }
            }
        }
    }
    
    private func prepareChangedBallsForScene15() {
        // First restore the exact scene 13 configuration
        balls = scene13Configuration.map { ball in
            Ball(position: ball.position,
                 color: ball.color,
                 pressCount: ball.pressCount,
                 isActive: true,
                 alignment: ball.alignment,
                 scale: ball.scale)
        }
        
        // Find two balls of different colors to exchange
        let ballsByColor = Dictionary(grouping: balls.enumerated(), by: { $0.element.color })
        guard let yellowBalls = ballsByColor[.yellow]?.shuffled(),
              let nonYellowBalls = (ballsByColor[.red] ?? ballsByColor[.blue])?.shuffled(),
              let ball1 = yellowBalls.first,
              let ball2 = nonYellowBalls.first else { return }
        
        let index1 = ball1.offset
        let index2 = ball2.offset
        
        changedBallPositions = Set([balls[index1].id, balls[index2].id])
        
        withAnimation(.spring()) {
            let tempPosition = balls[index1].position
            balls[index1].position = balls[index2].position
            balls[index2].position = tempPosition
        }
        wrongBallsPressed.removeAll()
    }
    
    private func setupScene(_ targetScene: Int) {
        guard targetScene >= 1 && targetScene <= 27 else { return }
        // Reset game state
        balls = [Ball(position: CGPoint(x: UIScreen.main.bounds.width/3, 
                                      y: UIScreen.main.bounds.height/2))]
        backgroundColor = .white
        pressCount = 0
        changedBallPositions.removeAll()
        wrongBallsPressed.removeAll()
        
        // Play through scenes
        for sceneNum in 1...targetScene {
            switch sceneNum {
            case 2:
                // Add second ball
                let spacing: CGFloat = 100
                let newPosition = CGPoint(
                    x: (balls.last?.position.x ?? 0) + spacing,
                    y: balls[0].position.y
                )
                balls.append(Ball(position: newPosition))
                
            case 5...7:
                // Setup colored balls
                if sceneNum == 5 {
                    balls[0].color = .yellow
                } else if sceneNum == 6 {
                    balls[0].color = .red
                } else {
                    balls[0].color = .blue
                }
                
            case 8...12:
                // Setup multiple balls for shake/tilt scenes
                if balls.count < 15 {
                    for _ in 0..<15 {
                        balls.append(Ball(position: randomPosition()))
                    }
                }
                
            case 13:
                // Setup colored balls grid
                balls = []
                for _ in 0..<15 {
                    balls.append(Ball(position: randomPosition(), color: .yellow))
                }
                arrangeInGrid()
                
            case 14:
                backgroundColor = .black
                balls.forEach { ball in
                    if let idx = balls.firstIndex(where: { $0.id == ball.id }) {
                        balls[idx].isActive = ball.color == .yellow
                    }
                }
                
            default:
                break  // No special setup needed for other scenes
            }
        }
        
        scene = targetScene
    }
}

struct BallView: View {
    let ball: Ball
    let scene: Int
    let onTap: () -> Void
    let onRub: () -> Void
    
    var body: some View {
        Circle()
            .fill(ball.color)
            .frame(width: 60, height: 60)
            .position(ball.position)
            .opacity(ball.isActive ? 1 : 0)
            .onTapGesture(perform: onTap)
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if scene == 3 || scene == 4 {
                        onRub()
                    }
                }
            )
    }
}

#Preview {
    ContentView()
}