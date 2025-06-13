//
//  OneShot.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-13.
//

import SwiftUI
import CoreBluetooth

struct OneShotView: View {
    @StateObject private var bleManager = BluetoothManager()

    var body: some View {
        NavigationStack {
            VStack {
                if bleManager.isConnected {
                    GeometryReader { geometry in
                        VStack {
                            Spacer()

                            Button(action: {
                                bleManager.takePhoto()
                            }) {
                                Image(systemName: "camera.aperture")
                                    .font(.system(size: geometry.size.width * 0.8))
                            }
                            .padding()
                            .foregroundColor(.white)
                            
                            Spacer()
                        }
                    }
                    .navigationTitle(bleManager.connectedPeripheral?.name ?? "unknown_device".localized(comment: "Unknown Device"))
                } else {
                    VStack {
                        if bleManager.peripherals.isEmpty {
                            Text("no_devices_found".localized(comment: "No devices found"))
                        } else {
                            List(bleManager.peripherals, id: \.identifier) { peripheral in
                                Button(action: {
                                    bleManager.connect(to: peripheral)
                                }) {
                                    Text(peripheral.name ?? "unknown_device".localized(comment: "Unknown Device"))
                                }
                            }
                        }
                    }
                    .navigationTitle("bluetooth_devices".localized(comment: "Bluetooth Devices"))
                }
            }
        }
    }
}
