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
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                if bleManager.isShootingMode {
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
                                            
                                            if !isPressed && !isBurstMode {
                                                isPressed = true
                                                bleManager.takePhoto()
                                            } else if !isPressed && isBurstMode {
                                                bleManager.pressShutter()
                                            }
                                        }
                                        .onEnded { _ in
                                            invalidateTimers()
                                            startIncreaseAnimation()
                                            
                                            if isBurstMode {
                                                bleManager.releaseShutter()
                                            }
                                            isPressed = false
                                        }
                                )
                        }
                        
                        Spacer()
                    }
                } else {
                    let imageSize = geometry.size.width * 0.25
                    VStack {
                        Button(action: {
                            bleManager.pressNavigationButton(button: BluetoothManager.Button.up)
                        }) {
                            Image(systemName: "arrowtriangle.up")
                                .foregroundColor(Color(UIColor.label))
                                .font(.system(size: imageSize, weight: .thin))
                        }
                        
                        HStack {
                            Button(action: {
                                bleManager.pressNavigationButton(button: BluetoothManager.Button.left)
                            }) {
                                Image(systemName: "arrowtriangle.left")
                                    .foregroundColor(Color(UIColor.label))
                                    .font(.system(size: imageSize, weight: .thin))
                            }
                            Button(action: {
                                bleManager.pressNavigationButton(button: BluetoothManager.Button.middle)
                            }) {
                                Image(systemName: "circle")
                                    .foregroundColor(Color(UIColor.label))
                                    .font(.system(size: imageSize, weight: .thin))
                            }
                            Button(action: {
                                bleManager.pressNavigationButton(button: BluetoothManager.Button.right)
                            }) {
                                Image(systemName: "arrowtriangle.right")
                                    .foregroundColor(Color(UIColor.label))
                                    .font(.system(size: imageSize, weight: .thin))
                            }
                        }.padding()
                        
                        Button(action: {
                            bleManager.pressNavigationButton(button: BluetoothManager.Button.down)
                        }) {
                            Image(systemName: "arrowtriangle.down")
                                .foregroundColor(Color(UIColor.label))
                                .font(.system(size: imageSize, weight: .thin))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }

                HStack {
                    Spacer()
                    Button(action: {
                        bleManager.switchMode()
                    }) {
                        Image(systemName: !bleManager.isShootingMode ? "camera.aperture" : "play.square")
                            .font(.system(size: geometry.size.width * 0.07, weight: .thin))
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .foregroundColor(Color(UIColor.label))
                            .cornerRadius(10)
                    }
                    .padding()
                }
            }
        }
    }
    
    private func invalidateTimers() {
        decreaseTimer?.invalidate()
        increaseTimer?.invalidate()
    }
    
    private func startDecreaseAnimation() {
        decreaseTimer = Timer.scheduledTimer(withTimeInterval: 0.002, repeats: true) { [self] _ in
            innerRadiusFactor -= 0.01
            if innerRadiusFactor <= 0 {
                innerRadiusFactor = 0
                invalidateTimers()
            }
        }
    }
    
    private func startIncreaseAnimation() {
        increaseTimer = Timer.scheduledTimer(withTimeInterval: 0.002, repeats: true) { [self] _ in
            innerRadiusFactor += 0.01
            if innerRadiusFactor >= 0.5 {
                innerRadiusFactor = 0.5
                invalidateTimers()
            }
        }
    }
}

