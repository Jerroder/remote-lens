//
//  ContentView.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-10.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @StateObject private var bleManager = BluetoothManager()

    var body: some View {
        NavigationView {
            VStack {
                if bleManager.isConnected {
                    VStack {
                        Button("Take Photo") {
                            bleManager.takePhoto()
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        HStack {
                            Button("Press Shutter") {
                                bleManager.pressShutter()
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)

                            Button("Release Shutter") {
                                bleManager.releaseShutter()
                            }
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding()
                    }
                    .navigationTitle(bleManager.connectedPeripheral?.name ?? "Unknown Device")
                } else {
                    VStack {
                        if bleManager.peripherals.isEmpty {
                            Text("No devices found")
                        } else {
                            List(bleManager.peripherals, id: \.identifier) { peripheral in
                                Button(action: {
                                    bleManager.connect(to: peripheral)
                                }) {
                                    Text(peripheral.name ?? "Unknown Device")
                                }
                            }
                        }
                    }
                    .navigationTitle("Bluetooth Devices")
                }
            }
        }
    }
}
