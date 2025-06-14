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

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue {
                    // bleManager.takePhoto()
                    bleManager.pressShutter()
                    isButtonPressed = true
                } else {
                    bleManager.releaseShutter()
                    isButtonPressed = false
                }
            }
    }
}

struct OneShotView: View {
    @ObservedObject var bleManager: BluetoothManager

    @State private var isButtonPressed = false

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()

                Button(action: {}) {
                    Image(systemName: isButtonPressed ? "circle.fill" : "camera.aperture")
                        .font(.system(size: geometry.size.width * 0.7))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(TakePhotoOnPress(bleManager: bleManager, isButtonPressed: $isButtonPressed))

                Spacer()
            }
        }
    }
}
