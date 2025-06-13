//
//  OneShot.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-13.
//

import SwiftUI

struct OneShotView: View {
    @ObservedObject var bleManager: BluetoothManager

    @State private var isButtonPressed = false

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                Image(systemName: isButtonPressed ? "circle.fill" : "camera.aperture")
                    .font(.system(size: geometry.size.width * 0.7))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isButtonPressed = true
                                }
                                bleManager.takePhoto()
                            }
                            .onEnded { _ in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isButtonPressed = false
                                }
                            }
                    )
                    .padding()
                    .foregroundColor(.white)
                
                Spacer()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        bleManager.disconnect()
                    }) {
                        Label("disconnect".localized(comment: "Disconnect"), systemImage: "wifi.slash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}
