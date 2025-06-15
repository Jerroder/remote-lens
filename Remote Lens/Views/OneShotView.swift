//
//  OneShotView.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-13.
//

import SwiftUI

struct TakePhotoOnPress: ButtonStyle {
    @ObservedObject var bleManager: BluetoothManager
    @Binding var isButtonPressed: Bool
    @Binding var isBurstMode: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue {
                    if isBurstMode {
                        bleManager.pressShutter()
                    } else {
                        bleManager.takePhoto()
                    }
                    isButtonPressed = true
                } else {
                    if isBurstMode {
                        bleManager.releaseShutter()
                    }
                    isButtonPressed = false
                }
            }
    }
}

struct OneShotView: View {
    @ObservedObject var bleManager: BluetoothManager

    @State private var isButtonPressed = false
    @State private var isBurstMode: Bool = UserDefaults.standard.bool(forKey: "isBurstMode")

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Toggle("burst_mode".localized(comment: "Burst mode"), isOn: $isBurstMode)
                    .padding()
                    .onChange(of: isBurstMode) { oldValue, newValue in
                        UserDefaults.standard.set(newValue, forKey: "isBurstMode")
                    }

                Spacer()

                Button(action: {}) {
                    Image(systemName: isButtonPressed ? "circle.fill" : "camera.aperture")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width * 0.7, height: geometry.size.width * 0.7)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(TakePhotoOnPress(bleManager: bleManager, isButtonPressed: $isButtonPressed, isBurstMode: $isBurstMode))

                Spacer()
            }
        }
    }
}
