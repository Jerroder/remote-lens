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
    @ObservedObject var locationManager: LocationManager
    @Binding var showGeotagSheet: Bool
    @Binding var waitForFix: Bool
    @Binding var selectedOption: Int
    
    @State private var isButtonPressed = false
    @State private var isBurstMode: Bool = UserDefaults.standard.bool(forKey: "isBurstMode")
    
    @State private var innerRadiusFactor: CGFloat = 0.5
    @State private var decreaseTimer: Timer?
    @State private var increaseTimer: Timer?
    
    @State private var isPressed: Bool = false
    @State private var isSwiping: Bool = false
    @State private var hasBeenPressed: Bool = false
    
    @State private var initialTouchPosition: CGSize = .zero
    
    @State private var hexFields: [String] = Array(repeating: "", count: 16)
    
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
                                        .onChanged { value in
                                            if initialTouchPosition == .zero {
                                                initialTouchPosition = value.translation
                                            }
                                            
                                            // Check if the finger has moved significantly
                                            let translation = value.translation
                                            let deltaX = abs(translation.width - initialTouchPosition.width)
                                            let deltaY = abs(translation.height - initialTouchPosition.height)
                                            
                                            if deltaX < 1 && deltaY < 1 {
                                                if !isPressed {
                                                    isPressed = true
                                                    
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
                                                }
                                                
                                                invalidateTimers()
                                                startDecreaseAnimation()
                                                
                                                // Prevent the popup from hijacking the view and not trigger .onEnded
                                                if locationManager.showGPSDeniedAlert {
                                                    if isBurstMode {
                                                        bleManager.releaseShutter()
                                                    }
                                                    isPressed = false
                                                    invalidateTimers()
                                                    startIncreaseAnimation()
                                                    initialTouchPosition = .zero
                                                }
                                            }
                                        }
                                        .onEnded { _ in
                                            if isBurstMode {
                                                bleManager.releaseShutter()
                                            }
                                            isPressed = false
                                            invalidateTimers()
                                            startIncreaseAnimation()
                                            initialTouchPosition = .zero
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
                                            withAnimation {
                                                hasBeenPressed = true
                                            }
                                            
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
                
                HStack {
                    if bleManager.isShootingMode {
                        if bleManager.hasAutofocusFailed || locationManager.isGeotagginEnabled {
                            Spacer()
                            VStack {
                                Text(bleManager.hasAutofocusFailed ? "could_not_autofocus".localized(comment: "Could not autofocus") : "")
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                
                                if !locationManager.isLocationServiceEnabled {
                                    Text("location_access_denied".localized(comment: "Location access denied"))
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                } else if locationManager.isLoading {
                                    Text("waiting_for_gps".localized(comment: "Waiting for GPS fix"))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                }
                            }
                        } else {
                            Spacer()
                        }
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
    } /* body */
    
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
