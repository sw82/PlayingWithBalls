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
        Ball(position: CGPoint(x: 100, y: 400))
    ]
    @State private var lastRubbedBallId: UUID?
    @State private var pressCount: Int = 0
    @State private var backgroundColor: Color = .white
    @State private var changedBallPositions: Set<UUID> = []
    @State private var wrongBallsPressed: Set<UUID> = []
    @State private var hasCompletedOnce = false
    @State private var screenSize: CGSize = .zero
    @StateObject private var motionManager = BallMotionManager()
    @StateObject private var microphoneMonitor = MicrophoneMonitor()
    @State private var scene13Configuration: [Ball] = []

    var instructionText: String {
        switch scene {
        case 1:  return "Press the yellow ball"
        case 2:  return "Press the yellow ball again"
        case 3:  return "Gently rub your finger over the yellow ball"
        case 4:  return "Now gently rub your finger over another yellow ball"
        case 5:  return "Now press 5 times the yellow ball"
        case 6:  return "Now press 5 times the red ball"
        case 7:  return "Now press 5 times the blue ball"
        case 8:  return "Now shake the phone a bit"
        case 9:  return "Now shake it even more"
        case 10: return "Try to tilt the phone to the left side"
        case 11: return "Try to tilt the phone to the right side"
        case 12: return "Shake the phone to distribute them again"
        case 13: return "Press on all yellow balls"
        case 14: return "Funny, turn it on the lights again and by pressing on all yellow balls again"
        case 15: return "Two balls are not in the right position. Do you know which?"
        case 16: return "Shake it again"
        case 17: return "Blow a bit"
        case 18: return "Blow a bit stronger"
        case 19: return "Hold the phone upright so the balls can sink again"
        case 20: return "Clap in your hands"
        case 21: return "Blow a bit"
        case 22: return "Clap twice"
        case 23: return "Clap three times"
        case 24: return "Clap again"
        case 25: return "Applause"
        case 26: return "More applause"
        case 27: return "Oh no. Too much. Press the white ball"
        case 28: return "Congratulations! Press the yellow ball to start over"
        default: return ""
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundColor.ignoresSafeArea()

                VStack {
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
                    HStack {
                        debugButton("Shake") { motionManager.simulateShake() }
                        debugButton("Tilt Left") { handleTilt(direction: .left) }
                        debugButton("Tilt Right") { handleTilt(direction: .right) }
                        debugButton("Blow") { handleBlow() }
                        debugButton("Upright") { handleDeviceUpright() }
                        debugButton("Clap") { handleClap() }
                    }
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
                screenSize = geometry.size
                balls[0].position = CGPoint(
                    x: geometry.size.width / 3,
                    y: geometry.size.height / 2
                )
                motionManager.startMotionUpdates()
                microphoneMonitor.startMonitoring()
            }
            .onDisappear {
                motionManager.stopMotionUpdates()
                microphoneMonitor.stopMonitoring()
                resetGame()
            }
            .onChange(of: geometry.size) { _, newSize in
                screenSize = newSize
            }
            .onChange(of: motionManager.shakeCount) { _, _ in
                handleShake()
            }
            .onChange(of: motionManager.tiltDirection) { _, newDirection in
                handleTilt(direction: newDirection)
            }
            .onChange(of: microphoneMonitor.blowDetected) { _, detected in
                if detected { handleBlow() }
            }
            .onChange(of: microphoneMonitor.clapDetected) { _, detected in
                if detected { handleClap() }
            }
            .onChange(of: motionManager.isUpright) { _, upright in
                if upright { handleDeviceUpright() }
            }
            .onChange(of: scene) { _, newScene in
                if newScene == 14 {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        backgroundColor = .black
                        for i in balls.indices {
                            balls[i].isActive = balls[i].color == .yellow
                        }
                    }
                }
            }
        }
    }

    #if DEBUG
    private func debugButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .padding(8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
    #endif

    // MARK: - Tap Handling

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

        case 5...7:
            handleFivePressScene(ball: ball, index: index)

        case 13:
            if ball.color == .yellow && ball.isActive {
                withAnimation {
                    balls[index].isActive = false
                    if !balls.contains(where: { $0.color == .yellow && $0.isActive }) {
                        scene13Configuration = balls.map { b in
                            Ball(position: b.position, color: b.color,
                                 pressCount: b.pressCount, isActive: true,
                                 alignment: b.alignment, scale: b.scale)
                        }
                        for i in balls.indices {
                            balls[i].isActive = balls[i].color == .yellow
                        }
                        backgroundColor = .black
                        scene = 14
                    }
                }
            }

        case 14:
            if ball.color == .yellow && ball.isActive {
                withAnimation {
                    balls[index].isActive = false
                    if !balls.contains(where: { $0.color == .yellow && $0.isActive }) {
                        backgroundColor = .white
                        prepareChangedBallsForScene15()
                        scene = 15
                    }
                }
            }

        case 15:
            if changedBallPositions.contains(ballId) {
                withAnimation {
                    wrongBallsPressed.insert(ballId)
                    if wrongBallsPressed == changedBallPositions {
                        balls = scene13Configuration.map { b in
                            Ball(position: b.position, color: b.color,
                                 pressCount: b.pressCount, isActive: true,
                                 alignment: b.alignment, scale: b.scale)
                        }
                        backgroundColor = .black
                        scene = 16
                    }
                }
            }

        case 27:
            if ball.color == .white {
                withAnimation {
                    scene = 28
                    hasCompletedOnce = true
                }
            }

        case 28:
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

    // MARK: - Rub Handling

    private func handleRub(ballId: UUID) {
        guard scene == 3 || scene == 4 else { return }
        guard let index = balls.firstIndex(where: { $0.id == ballId }) else { return }
        guard balls[index].isActive && balls[index].color == .yellow else { return }

        if scene == 3 {
            withAnimation {
                balls[index].color = .red
                lastRubbedBallId = ballId
                scene = 4
            }
        } else if scene == 4 && ballId != lastRubbedBallId {
            withAnimation {
                balls[index].color = .blue
                scene = 5
            }
        }
    }

    // MARK: - Five Press Scene

    private func handleFivePressScene(ball: Ball, index: Int) {
        guard ball.isActive else { return }

        let correctColor: Color
        let nextScene: Int

        switch scene {
        case 5: correctColor = .yellow; nextScene = 6
        case 6: correctColor = .red;    nextScene = 7
        case 7: correctColor = .blue;   nextScene = 8
        default: return
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

    private func createFiveBalls(fromBallId: UUID, color: Color, alignment: BallAlignment) {
        guard let index = balls.firstIndex(where: { $0.id == fromBallId }) else { return }
        let origin = balls[index].position
        let spacing: CGFloat = 70

        balls.remove(at: index)
        for i in 0..<5 {
            let position: CGPoint
            if alignment == .vertical {
                position = CGPoint(x: origin.x, y: origin.y - spacing * 2 + spacing * CGFloat(i))
            } else {
                position = CGPoint(x: origin.x - spacing * 2 + spacing * CGFloat(i), y: origin.y)
            }
            balls.append(Ball(position: position, color: color, alignment: alignment))
        }
    }

    // MARK: - Shake Handling

    private func handleShake() {
        switch scene {
        case 8:
            withAnimation(.spring()) {
                for i in balls.indices {
                    balls[i].position.x += CGFloat.random(in: -20...20)
                    balls[i].position.y += CGFloat.random(in: -20...20)
                }
                scene = 9
            }

        case 9:
            withAnimation(.spring()) {
                for i in balls.indices {
                    balls[i].position = randomPosition()
                }
                scene = 10
            }

        case 12:
            withAnimation(.spring()) {
                arrangeInGrid()
                scene = 13
            }

        case 16:
            withAnimation(.spring()) {
                arrangeInGrid()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring()) {
                        for i in balls.indices {
                            if CGFloat.random(in: 0...1) > 0.5 {
                                balls[i].color = [Color.yellow, .red, .blue].randomElement() ?? .yellow
                            }
                        }
                        arrangeInCircle()
                        scene = 17
                    }
                }
            }

        default:
            break
        }
    }

    // MARK: - Blow Handling

    private func handleBlow() {
        switch scene {
        case 17:
            withAnimation(.spring()) {
                for i in balls.indices {
                    balls[i].position.y -= 50
                    balls[i].position.x += CGFloat.random(in: -50...50)
                }
                scene = 18
            }

        case 18:
            withAnimation(.spring()) {
                for i in balls.indices {
                    balls[i].position.y -= screenSize.height * CGFloat.random(in: 0.6...0.9)
                    balls[i].position.x += CGFloat.random(in: -100...100)
                }
                scene = 19
            }

        case 21:
            withAnimation(.spring()) {
                for i in balls.indices {
                    balls[i].scale *= 1.2
                }
                scene = 22
            }

        default:
            break
        }
    }

    // MARK: - Clap Handling

    private func handleClap() {
        switch scene {
        case 20:
            withAnimation(.spring()) {
                for i in balls.indices {
                    balls[i].scale = 2.0
                }
                scene = 21
            }

        case 22:
            withAnimation(.spring()) {
                for i in balls.indices {
                    balls[i].scale = 8.0
                    balls[i].position.x += CGFloat.random(in: -50...50)
                    balls[i].position.y += CGFloat.random(in: -50...50)
                }
                scene = 23
            }

        case 23:
            withAnimation(.spring()) {
                for i in balls.indices {
                    balls[i].scale = 16.0
                    balls[i].position.x += CGFloat.random(in: -70...70)
                    balls[i].position.y += CGFloat.random(in: -70...70)
                }
                scene = 24
            }

        case 24:
            withAnimation(.spring()) {
                for i in balls.indices {
                    balls[i].scale = 32.0
                    balls[i].color = .yellow
                }
                scene = 25
            }

        case 25:
            withAnimation(.spring()) {
                createFinalScene()
                scene = 26
            }

        case 26:
            withAnimation(.spring()) {
                scene = 27
            }

        default:
            break
        }
    }

    // MARK: - Orientation Handling

    private func handleDeviceUpright() {
        guard scene == 19 else { return }

        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            for i in balls.indices {
                let delay = Double.random(in: 0...0.5)
                let targetX = CGFloat.random(in: 50...(screenSize.width - 50))
                let targetY = CGFloat.random(in: screenSize.height * 0.4...screenSize.height * 0.8)

                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        guard i < balls.count else { return }
                        balls[i].position = CGPoint(x: targetX, y: targetY)
                    }
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                scene = 20
            }
        }
    }

    // MARK: - Tilt Handling

    private func handleTilt(direction: TiltDirection) {
        switch scene {
        case 10 where direction == .left:
            moveBallsToSide(.left)
            scene = 11
        case 11 where direction == .right:
            moveBallsToSide(.right)
            scene = 12
        default:
            break
        }
    }

    private func moveBallsToSide(_ side: TiltDirection) {
        withAnimation(.spring()) {
            for i in balls.indices {
                switch side {
                case .left:
                    balls[i].position.x = 50 + CGFloat.random(in: 0...50)
                case .right:
                    balls[i].position.x = screenSize.width - 100 + CGFloat.random(in: 0...50)
                case .none:
                    break
                }
            }
        }
    }

    // MARK: - Helpers

    private func randomPosition() -> CGPoint {
        CGPoint(
            x: CGFloat.random(in: 50...(screenSize.width - 50)),
            y: CGFloat.random(in: 100...(screenSize.height - 100))
        )
    }

    private func resetGame() {
        withAnimation {
            balls = [Ball(position: CGPoint(x: screenSize.width / 3, y: screenSize.height / 2))]
            backgroundColor = .white
            pressCount = 0
            changedBallPositions.removeAll()
            wrongBallsPressed.removeAll()
            lastRubbedBallId = nil
            hasCompletedOnce = false
        }
    }

    private func createFinalScene() {
        let center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        balls = [
            Ball(position: center, color: .yellow, scale: 50.0),
            Ball(position: center, color: .white, scale: 2.0)
        ]
    }

    private func arrangeInGrid() {
        let columns = 5
        let rows = 3
        let spacing: CGFloat = 70

        let startX = (screenSize.width - CGFloat(columns - 1) * spacing) / 2
        let startY = (screenSize.height - CGFloat(rows - 1) * spacing) / 2

        var positions: [CGPoint] = []
        for row in 0..<rows {
            for col in 0..<columns {
                positions.append(CGPoint(
                    x: startX + CGFloat(col) * spacing,
                    y: startY + CGFloat(row) * spacing
                ))
            }
        }
        positions.shuffle()

        withAnimation(.spring()) {
            for i in balls.indices where i < positions.count {
                balls[i].position = positions[i]
            }
        }
    }

    private func arrangeInCircle() {
        let center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        let radius = min(screenSize.width, screenSize.height) / 3

        withAnimation(.spring()) {
            for i in balls.indices {
                let angle = (2.0 * .pi * Double(i)) / Double(balls.count)
                balls[i].position = CGPoint(
                    x: center.x + radius * cos(angle),
                    y: center.y + radius * sin(angle)
                )
            }
        }
    }

    private func prepareChangedBallsForScene15() {
        balls = scene13Configuration.map { b in
            Ball(position: b.position, color: b.color,
                 pressCount: b.pressCount, isActive: true,
                 alignment: b.alignment, scale: b.scale)
        }

        let ballsByColor = Dictionary(grouping: balls.indices, by: { balls[$0].color })
        guard let yellowIndices = ballsByColor[.yellow]?.shuffled(),
              let nonYellowIndices = (ballsByColor[.red] ?? ballsByColor[.blue])?.shuffled(),
              let i1 = yellowIndices.first,
              let i2 = nonYellowIndices.first else { return }

        changedBallPositions = [balls[i1].id, balls[i2].id]

        withAnimation(.spring()) {
            let temp = balls[i1].position
            balls[i1].position = balls[i2].position
            balls[i2].position = temp
        }
        wrongBallsPressed.removeAll()
    }
}

// MARK: - Ball View

struct BallView: View {
    let ball: Ball
    let scene: Int
    let onTap: () -> Void
    let onRub: () -> Void

    var body: some View {
        Circle()
            .fill(ball.color)
            .frame(width: 60, height: 60)
            .scaleEffect(ball.scale)
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
