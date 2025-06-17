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

struct Arrowhead: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let leftPoint = CGPoint(x: rect.minX, y: rect.maxY)
        let topPoint = CGPoint(x: rect.midX, y: rect.minY)
        let rightPoint = CGPoint(x: rect.maxX, y: rect.maxY)
        
        path.move(to: leftPoint)
        path.addLine(to: topPoint)
        path.move(to: rightPoint)
        path.addLine(to: topPoint)
        
        return path
    }
}

struct AnimatedArrowheads: View {
    @State private var opacityValues: [Double] = [0.1, 0.1, 0.1]
    @State private var currentIndex = 2
    @State private var isWaiting = false
    
    let animationTimer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    let waitTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ZStack {
                ForEach(0..<4) { i in
                    VStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Arrowhead()
                                .stroke(lineWidth: 2)
                                .frame(width: 30, height: 8)
                                .opacity(self.opacityValues[index])
                        }
                    }
                    .rotationEffect(self.rotationAngleForIndex(i))
                    .position(self.positionForIndex(i, center: center))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(width: 200, height: 200)
        .onReceive(animationTimer) { _ in
            guard !isWaiting else {
                withAnimation(.easeInOut(duration: 1.5)) {
                    opacityValues[0] = 0.1
                }
                return
            }
            withAnimation(.easeInOut(duration: 1.5)) {
                opacityValues = [0.1, 0.1, 0.1]
                
                opacityValues[currentIndex] = 1
                
                currentIndex = (currentIndex - 1 + 3) % 3
                
                if currentIndex == 2 {
                    isWaiting = true
                }
            }
        }
        .onReceive(waitTimer) { _ in
            guard isWaiting else { return }
            isWaiting = false
        }
    }
    
    func rotationAngleForIndex(_ index: Int) -> Angle {
        return Angle(degrees: Double(index) * 90)
    }
    
    func positionForIndex(_ index: Int, center: CGPoint) -> CGPoint {
        let hOffset: CGFloat = 115
        let vOffset: CGFloat = 140
        
        switch index {
        case 0: // Top
            return CGPoint(x: center.x, y: center.y - vOffset)
        case 1: // Right
            return CGPoint(x: center.x + hOffset, y: center.y)
        case 2: // Bottom
            return CGPoint(x: center.x, y: center.y + vOffset)
        case 3: // Left
            return CGPoint(x: center.x - hOffset, y: center.y)
        default:
            return center
        }
    }
}

struct ConcentricCirclesView: View {
    @State private var opacityValues: [Double] = [0.1, 0.1, 0.1]
    @State private var currentIndex = 0
    @State private var isWaiting = false
    
    let animationTimer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    let waitTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .stroke(lineWidth: 2)
                    .frame(width: 10 + CGFloat(index) * 15, height: 10 + CGFloat(index) * 15)
                    .opacity(opacityValues[index])
            }
        }
        .frame(width: 150, height: 150)
        .onReceive(animationTimer) { _ in
            guard !isWaiting else {
                withAnimation(.easeInOut(duration: 1.5)) {
                }
                return
            }
            withAnimation(.easeInOut(duration: 1.5)) {
                opacityValues = [0.1, 0.1, 0.1]
                
                opacityValues[currentIndex] = 1
                
                currentIndex = (currentIndex + 1) % 3
                
                if currentIndex == 0 {
                    isWaiting = true
                }
            }
        }
        .onReceive(waitTimer) { _ in
            guard isWaiting else { return }
            isWaiting = false
        }
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
    
    @State private var currentTranslation: CGSize = .zero
    @State private var isSwiping: Bool = false
    
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
                        } /* ZStack */
                        
                        Spacer()
                    } /* VStack */
                } else {
                    VStack {
                        Spacer()
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(UIColor.secondarySystemBackground), lineWidth: 3)
                                .background(Color.clear)
                                .contentShape(Rectangle())
                                .padding()
                                .gesture(
                                    DragGesture(minimumDistance: 50, coordinateSpace: .local)
                                        .onChanged { value in
                                            currentTranslation = value.translation
                                            let horizontalSwipe = abs(value.translation.width) > abs(value.translation.height)
                                            
                                            if horizontalSwipe {
                                                if value.translation.width < 0 {
                                                    if !isSwiping {
                                                        isSwiping = true
                                                        bleManager.pressNavigationButton(button: BluetoothManager.Buttons.left)
                                                    }
                                                } else if value.translation.width > 0 {
                                                    if !isSwiping {
                                                        isSwiping = true
                                                        bleManager.pressNavigationButton(button: BluetoothManager.Buttons.right)
                                                    }
                                                }
                                            } else {
                                                if value.translation.height < 0 {
                                                    if !isSwiping {
                                                        isSwiping = true
                                                        bleManager.pressNavigationButton(button: BluetoothManager.Buttons.up)
                                                    }
                                                } else if value.translation.height > 0 {
                                                    if !isSwiping {
                                                        isSwiping = true
                                                        bleManager.pressNavigationButton(button: BluetoothManager.Buttons.down)
                                                    }
                                                }
                                            }
                                        }
                                        .onEnded { value in
                                            isSwiping = false
                                        }
                                )
                                .onTapGesture {
                                    bleManager.pressNavigationButton(button: BluetoothManager.Buttons.middle)
                                }
                            
                            AnimatedArrowheads()
                            ConcentricCirclesView()
                        } /* ZStack */
                    } /* VStack */
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } /* if */
                
                HStack {
                    if bleManager.isShootingMode {
                        Spacer()
                    } else {
                        Button(action: {
                            bleManager.pressNavigationButton(button: BluetoothManager.Buttons.zoomOut)
                        }) {
                            Image(systemName: "minus.magnifyingglass")
                                .font(.system(size: geometry.size.width * 0.07, weight: .thin))
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .foregroundColor(Color(UIColor.label))
                                .cornerRadius(10)
                        }
                        .padding()
                        
                        Spacer()
                        
                        Button(action: {
                            bleManager.pressNavigationButton(button: BluetoothManager.Buttons.zoomIn)
                        }) {
                            Image(systemName: "plus.magnifyingglass")
                                .font(.system(size: geometry.size.width * 0.07, weight: .thin))
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .foregroundColor(Color(UIColor.label))
                                .cornerRadius(10)
                        }
                        .padding()
                        
                        Spacer()
                    }
                    
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
                } /* HStack */
            } /* VStack */
        } /* GeometryReader */
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
