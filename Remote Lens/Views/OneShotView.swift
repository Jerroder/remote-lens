//
//  OneShotView.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-13.
//

import SwiftUI

struct OuterCircle: Shape {
    var outerRadiusFactor: CGFloat = 0.7
    
    func path(in rect: CGRect) -> Path {
        let center: CGPoint = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let outerRadius: CGFloat = min(rect.width, rect.height) * outerRadiusFactor
        
        var path = Path()
        
        // Draw the outer circle
        path.addArc(center: center, radius: outerRadius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        
        return path
    }
}

struct ShutterBlades: Shape {
    var innerRadiusFactor: CGFloat
    var outerRadiusFactor: CGFloat = 0.7
    
    func path(in rect: CGRect) -> Path {
        let center: CGPoint = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let innerRadius: CGFloat = min(rect.width, rect.height) * innerRadiusFactor
        let outerRadius: CGFloat = min(rect.width, rect.height) * outerRadiusFactor
        
        var path: Path = Path()
        
        // Draw the outer circle
        path.addArc(center: center, radius: outerRadius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        
        // Draw the inner circle
        path.addArc(center: center, radius: innerRadius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        
        // Draw arcs from the inner circle to the outer circle
        let tangentLineCount: Int = 6
        for i in 0..<tangentLineCount {
            let angle: Angle = Angle.degrees(Double(i) * 360 / Double(tangentLineCount))
            let tangentOffset: CGFloat = acos(innerRadius / outerRadius)
            
            let innerAngle: CGFloat = angle.radians - tangentOffset
            
            let innerPoint: CGPoint = CGPoint(
                x: center.x + innerRadius * CGFloat(cos(innerAngle)),
                y: center.y + innerRadius * CGFloat(sin(innerAngle))
            )
            
            let outerPoint: CGPoint = CGPoint(
                x: center.x + outerRadius * CGFloat(cos(angle.radians)),
                y: center.y + outerRadius * CGFloat(sin(angle.radians))
            )
            
            let midRadius: CGFloat = (innerRadius + outerRadius) / 2
            let controlPoint: CGPoint = CGPoint(
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
    @ObservedObject var locationManager: LocationManager
    @Binding var showGeotagSheet: Bool
    @Binding var waitForFix: Bool
    @Binding var selectedOption: Int
    
    @State private var isButtonPressed: Bool = false
    @State private var isBurstMode: Bool = UserDefaults.standard.bool(forKey: "isBurstMode")
    @State private var isVideoMode: Bool = UserDefaults.standard.bool(forKey: "isVideoMode")
    @State private var isTransitioningToVideo: Bool = UserDefaults.standard.bool(forKey: "isVideoMode")
    @State private var isVideoModeToggleDisabled: Bool = false
    
    @State private var shutterRadiusFactor: CGFloat = 0.7
    @State private var decreaseShutterTimer: Timer?
    @State private var increaseShutterTimer: Timer?
    
    @State private var recordSizeFactor: CGFloat = 0.0
    @State private var recordRadiusFactor: CGFloat = 1.0
    @State private var decreaseRecordTimer: Timer?
    @State private var increaseRecordTimer: Timer?
    
    @State private var isPressed: Bool = false
    @State private var isSwiping: Bool = false
    @State private var hasBeenPressed: Bool = false
    
    @State private var initialTouchPosition: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                if bleManager.isShootingMode {
                    VStack {
                        Toggle("video_mode".localized(comment: "Video mode"), isOn: Binding(
                            get: { self.isTransitioningToVideo },
                            set: { newValue in
                                self.isTransitioningToVideo = newValue
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    self.isVideoMode = newValue
                                }
                            }
                        ))
                            .padding(.horizontal)
                            .onChange(of: isTransitioningToVideo) { oldValue, newValue in
                                if !isVideoMode {
                                    transitionFromStills()
                                } else {
                                    transitionFromVideo()
                                }
                                UserDefaults.standard.set(newValue, forKey: "isVideoMode")
                            }
                            .disabled(isVideoModeToggleDisabled)
                        if !isTransitioningToVideo {
                            Toggle("burst_mode".localized(comment: "Burst mode"), isOn: $isBurstMode)
                                .padding(.horizontal)
                                .onChange(of: isBurstMode) { oldValue, newValue in
                                    UserDefaults.standard.set(newValue, forKey: "isBurstMode")
                                }
                        } else {
                            Spacer()
                                .frame(height: 40) // temporary
                        }
                        
                        Spacer()
                        
                        ZStack {
                            if !isVideoMode {
                                ShutterBlades(innerRadiusFactor: shutterRadiusFactor)
                                    .stroke(lineWidth: 3)
                                    .frame(width: geometry.size.width * 0.5, height: geometry.size.width * 0.5)
                                    .onAppear {
                                        transitionToStills()
                                    }
                            } else {
                                OuterCircle()
                                    .stroke(lineWidth: 3)
                                    .frame(width: geometry.size.width * 0.5, height: geometry.size.width * 0.5)
                                
                                Rectangle()
                                    .fill(Color.red)
                                    .cornerRadius(geometry.size.width * recordRadiusFactor)
                                    .frame(width: geometry.size.width * recordSizeFactor, height: geometry.size.width * recordSizeFactor)
                                    .onAppear {
                                        transitionToVideo()
                                    }
                            }
                            
                            Circle()
                                .fill(Color.clear)
                                .frame(width: geometry.size.width * 0.5, height: geometry.size.width * 0.5)
                                .contentShape(Circle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            if initialTouchPosition == .zero {
                                                initialTouchPosition = value.translation
                                            }
                                            
                                            // Check if the finger has moved significantly
                                            let translation: CGSize = value.translation
                                            let deltaX: CGFloat = abs(translation.width - initialTouchPosition.width)
                                            let deltaY: CGFloat = abs(translation.height - initialTouchPosition.height)
                                            
                                            if deltaX < 1 && deltaY < 1 {
                                                if !isPressed {
                                                    isPressed = true
                                                    invalidateShutterTimers()
                                                    
                                                    if !isVideoMode {
                                                        if selectedOption == 3 {
                                                            if waitForFix {
                                                                locationManager.getGPSData { data in
                                                                    bleManager.writeGPSValue(data: data)
                                                                    
                                                                    if !isBurstMode {
                                                                        bleManager.takePhoto()
                                                                    } else if isBurstMode {
                                                                        bleManager.pressShutter()
                                                                    }
                                                                }
                                                            } else {
                                                                bleManager.writeGPSValue(data: locationManager.getGPSData())
                                                                
                                                                if !isBurstMode {
                                                                    bleManager.takePhoto()
                                                                } else if isBurstMode {
                                                                    bleManager.pressShutter()
                                                                }
                                                            }
                                                        } else {
                                                            if !isBurstMode {
                                                                bleManager.takePhoto()
                                                            } else if isBurstMode {
                                                                bleManager.pressShutter()
                                                            }
                                                        }
                                                        
                                                        startPressAnimation()
                                                    } else {
                                                        if bleManager.isRecording {
                                                            isVideoModeToggleDisabled = false
                                                            stopRecordAnimation()
                                                            bleManager.stopRecording()
                                                        } else {
                                                            isVideoModeToggleDisabled = true
                                                            startRecordAnimation()
                                                            bleManager.startRecording()
                                                        }
                                                    }
                                                }
                                                
                                                // Prevent a popup from hijacking the view and not trigger .onEnded
                                                if locationManager.showGPSDeniedAlert {
                                                    if isBurstMode {
                                                        bleManager.releaseShutter()
                                                    }
                                                    isPressed = false
                                                    invalidateShutterTimers()
                                                    startReleaseAnimation()
                                                    initialTouchPosition = .zero
                                                }
                                            }
                                        }
                                        .onEnded { _ in
                                            if !isVideoMode {
                                                if isBurstMode {
                                                    bleManager.releaseShutter()
                                                }
                                                invalidateShutterTimers()
                                                startReleaseAnimation()
                                            }
                                            isPressed = false
                                            initialTouchPosition = .zero
                                        }
                                )
                                .sensoryFeedback(trigger: isPressed) { oldValue, newValue in
                                    let flex: SensoryFeedback.Flexibility = newValue ? SensoryFeedback.Flexibility.soft : SensoryFeedback.Flexibility.solid
                                    var amount: Double
                                    if !isVideoMode {
                                        amount = 1.0
                                    } else {
                                        // When starting a video recording || stopping a video recording
                                        if (isVideoModeToggleDisabled && newValue) || (!isVideoModeToggleDisabled && oldValue) {
                                            amount = 1.0
                                        } else {
                                            amount = 0.0
                                        }
                                    }
                                    return .impact(flexibility: flex, intensity: amount)
                                }
                            
                            Spacer()
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
                                            withAnimation {
                                                hasBeenPressed = true
                                            }
                                            
                                            let horizontalSwipe: Bool = abs(value.translation.width) > abs(value.translation.height)
                                            if horizontalSwipe {
                                                if value.translation.width < 0 {
                                                    if !isSwiping {
                                                        isSwiping = true
                                                        bleManager.pressNavigationButton(button: Buttons.left)
                                                    }
                                                } else if value.translation.width > 0 {
                                                    if !isSwiping {
                                                        isSwiping = true
                                                        bleManager.pressNavigationButton(button: Buttons.right)
                                                    }
                                                }
                                            } else {
                                                if value.translation.height < 0 {
                                                    if !isSwiping {
                                                        isSwiping = true
                                                        bleManager.pressNavigationButton(button: Buttons.up)
                                                    }
                                                } else if value.translation.height > 0 {
                                                    if !isSwiping {
                                                        isSwiping = true
                                                        bleManager.pressNavigationButton(button: Buttons.down)
                                                    }
                                                }
                                            }
                                        }
                                        .onEnded { value in
                                            isSwiping = false
                                        }
                                )
                                .onTapGesture {
                                    bleManager.pressNavigationButton(button: Buttons.middle)
                                    withAnimation {
                                        hasBeenPressed = true
                                    }
                                }
                            
                            if !hasBeenPressed {
                                AnimatedArrowheadsView()
                                ConcentricCirclesView()
                            }
                        } /* ZStack */
                    } /* VStack */
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } /* if */
                
                ZStack {
                    HStack {
                        if bleManager.isShootingMode {
                            if bleManager.hasAutofocusFailed || locationManager.isGeotagginEnabled {
                                VStack {
                                    if bleManager.hasAutofocusFailed {
                                        Text("could_not_autofocus".localized(comment: "Could not autofocus"))
                                            .font(.system(size: geometry.size.width * 0.04, weight: .bold))
                                            .foregroundColor(.red)
                                    }
                                    if !locationManager.isLocationServiceEnabled && locationManager.isGeotagginEnabled {
                                        Text("location_access_denied".localized(comment: "Location access denied"))
                                            .font(.system(size: geometry.size.width * 0.04, weight: .bold))
                                            .foregroundColor(.red)
                                    } else if locationManager.isLoading && locationManager.isGeotagginEnabled {
                                        Text("waiting_for_gps".localized(comment: "Waiting for GPS fix"))
                                            .font(.system(size: geometry.size.width * 0.04, weight: .semibold))
                                            .foregroundColor(.orange)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        } else {
                            Button(action: {
                                bleManager.pressNavigationButton(button: Buttons.zoomOut)
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
                                bleManager.pressNavigationButton(button: Buttons.zoomIn)
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
                            Spacer()
                            Spacer()
                        }
                    } /* HStack */
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            bleManager.switchMode()
                        }) {
                            Image(systemName: bleManager.isShootingMode ? "play.square" : "camera.aperture")
                                .font(.system(size: geometry.size.width * 0.07, weight: .thin))
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .foregroundColor(Color(UIColor.label))
                                .cornerRadius(10)
                        }
                        .padding()
                        .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.75), trigger: bleManager.isShootingMode)
                    }
                } /* ZStack */
            } /* VStack */
        } /* GeometryReader */
    } /* body */
    
    private func invalidateShutterTimers() {
        decreaseShutterTimer?.invalidate()
        increaseShutterTimer?.invalidate()
    }
    
    private func invalidateRecordTimers() {
        decreaseRecordTimer?.invalidate()
        increaseRecordTimer?.invalidate()
    }
    
    private func startPressAnimation() {
        decreaseShutterTimer?.invalidate()
        decreaseShutterTimer = Timer.scheduledTimer(withTimeInterval: 0.002, repeats: true) { [self] _ in
            shutterRadiusFactor -= 0.01
            if shutterRadiusFactor <= 0 {
                shutterRadiusFactor = 0
                invalidateShutterTimers()
            }
        }
    }
    
    private func startRecordAnimation() {
        decreaseShutterTimer?.invalidate()
        decreaseShutterTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [self] _ in
            recordRadiusFactor -= 0.01
            if recordRadiusFactor <= 0.02 {
                recordRadiusFactor = 0.02
                invalidateShutterTimers()
            }
        }
    }
    
    private func startReleaseAnimation() {
        increaseShutterTimer?.invalidate()
        increaseShutterTimer = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { [self] _ in
            shutterRadiusFactor += 0.01
            if shutterRadiusFactor >= 0.5 {
                shutterRadiusFactor = 0.5
                invalidateShutterTimers()
            }
        }
    }
    
    private func stopRecordAnimation() {
        increaseShutterTimer?.invalidate()
        increaseShutterTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [self] _ in
            recordRadiusFactor += 0.01
            if recordRadiusFactor >= recordSizeFactor * 0.5 {
                recordRadiusFactor = recordSizeFactor * 0.5
                invalidateShutterTimers()
            }
        }
    }
    
    private func transitionFromStills() {
        increaseShutterTimer?.invalidate()
        increaseShutterTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [self] _ in
            shutterRadiusFactor += 0.01
            if shutterRadiusFactor >= 0.7 {
                shutterRadiusFactor = 0.7
                invalidateShutterTimers()
            }
        }
    }
    
    private func transitionToStills() {
        decreaseShutterTimer?.invalidate()
        decreaseShutterTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [self] _ in
            shutterRadiusFactor -= 0.01
            if shutterRadiusFactor <= 0.5 {
                shutterRadiusFactor = 0.5
                invalidateShutterTimers()
            }
        }
    }
    
    private func transitionToVideo() {
        increaseRecordTimer?.invalidate()
        recordRadiusFactor = 0.3 * 0.5
        increaseRecordTimer = Timer.scheduledTimer(withTimeInterval: 0.005, repeats: true) { [self] _ in
            recordSizeFactor += 0.01
            if recordSizeFactor >= 0.3 {
                recordSizeFactor = 0.3
                invalidateRecordTimers()
            }
        }
    }
    
    private func transitionFromVideo() {
        decreaseRecordTimer?.invalidate()
        decreaseRecordTimer = Timer.scheduledTimer(withTimeInterval: 0.008, repeats: true) { [self] _ in
            recordSizeFactor -= 0.01
            if recordSizeFactor <= 0.0 {
                recordSizeFactor = 0.0
                invalidateRecordTimers()
            }
        }
    }
}
