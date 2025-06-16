//
//  OneShotView.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-13.
//

import SwiftUI

struct ShutterBlades: Shape {
    var innerRadiusFactor: CGFloat
    var outerRadiusFactor: CGFloat = 0.7

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let innerRadius: CGFloat = min(rect.width, rect.height) * innerRadiusFactor
        let outerRadius: CGFloat = min(rect.width, rect.height) * outerRadiusFactor

        var path = Path()

        // Draw the outer circle
        path.addArc(center: center, radius: outerRadius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)

        // Draw the inner circle
        path.addArc(center: center, radius: innerRadius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)

        // Draw arcs from the inner circle to the outer circle
        let tangentLineCount = 6
        for i in 0..<tangentLineCount {
            let angle = Angle.degrees(Double(i) * 360 / Double(tangentLineCount))
            let tangentOffset = acos(innerRadius / outerRadius)

            let innerAngle = angle.radians - tangentOffset

            let innerPoint = CGPoint(
                x: center.x + innerRadius * CGFloat(cos(innerAngle)),
                y: center.y + innerRadius * CGFloat(sin(innerAngle))
            )

            let outerPoint = CGPoint(
                x: center.x + outerRadius * CGFloat(cos(angle.radians)),
                y: center.y + outerRadius * CGFloat(sin(angle.radians))
            )

            let midRadius = (innerRadius + outerRadius) / 2
            let controlPoint = CGPoint(
                x: center.x + midRadius * CGFloat(cos(angle.radians - tangentOffset / 2)),
                y: center.y + midRadius * CGFloat(sin(angle.radians - tangentOffset / 2))
            )

            path.move(to: innerPoint)
            path.addQuadCurve(to: outerPoint, control: controlPoint)
        }

        return path
    }
}

struct OneShotView: View {
    @ObservedObject var bleManager: BluetoothManager
    
    @State private var isButtonPressed = false
    @State private var isBurstMode: Bool = UserDefaults.standard.bool(forKey: "isBurstMode")

    @State private var innerRadiusFactor: CGFloat = 0.5
    @State private var decreaseTimer: Timer?
    @State private var increaseTimer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Toggle("burst_mode".localized(comment: "Burst mode"), isOn: $isBurstMode)
                    .padding()
                    .onChange(of: isBurstMode) { oldValue, newValue in
                        UserDefaults.standard.set(newValue, forKey: "isBurstMode")
                    }

                Spacer()

                ZStack {
                    ShutterBlades(innerRadiusFactor: innerRadiusFactor)
                        .stroke(lineWidth: 3)
                        .frame(width: geometry.size.width * 0.5, height: geometry.size.width * 0.5)

                    Circle()
                        .fill(Color.clear)
                        .frame(width: geometry.size.width * 0.5, height: geometry.size.width * 0.5)
                        .contentShape(Circle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    invalidateTimers()
                                    startDecreaseAnimation()
                                    if isBurstMode {
                                        bleManager.pressShutter()
                                    } else {
                                        bleManager.takePhoto()
                                    }
                                }
                                .onEnded { _ in
                                    invalidateTimers()
                                    startIncreaseAnimation()
                                    if isBurstMode {
                                        bleManager.releaseShutter()
                                    }
                                }
                        )
                }

                Spacer()

                HStack {
                    Button(action: {
                        bleManager.switchToShooting()
                    }) {
                        Text("Shooting")
                    }
                    Button(action: {
                        bleManager.switchToPlayback()
                    }) {
                        Text("Playback")
                    }
                }
            }
        }
    }

    func invalidateTimers() {
        decreaseTimer?.invalidate()
        increaseTimer?.invalidate()
    }

    func startDecreaseAnimation() {
        decreaseTimer = Timer.scheduledTimer(withTimeInterval: 0.002, repeats: true) { [self] _ in
            innerRadiusFactor -= 0.01
            if innerRadiusFactor <= 0 {
                innerRadiusFactor = 0
                invalidateTimers()
            }
        }
    }

    func startIncreaseAnimation() {
        increaseTimer = Timer.scheduledTimer(withTimeInterval: 0.002, repeats: true) { [self] _ in
            innerRadiusFactor += 0.01
            if innerRadiusFactor >= 0.5 {
                innerRadiusFactor = 0.5
                invalidateTimers()
            }
        }
    }
}
