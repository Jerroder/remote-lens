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
    @State private var filterText = ""
    
    var filteredPeripherals: [CBPeripheral] {
        if filterText.isEmpty {
            return bleManager.peripherals
        } else {
            return bleManager.peripherals.filter { $0.name?.contains(filterText) ?? false }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                TextField("Filter Devices", text: $filterText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                List(filteredPeripherals, id: \.identifier) { peripheral in
                    Button(action: {
                        bleManager.connect(to: peripheral)
                    }) {
                        Text(peripheral.name ?? "Unknown Device")
                    }
                }
                .navigationTitle("BLE Devices")

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
            }
        }
    }
}

//struct ContentView: View {
//    @StateObject var bluetoothManager = BluetoothDiscovery()
//
//    var body: some View {
//        VStack {
//            Button(action: {
//                bluetoothManager.toggleBluetooth()
//            }) {
//                Text(bluetoothManager.isBluetoothEnabled ? "Turn Off Bluetooth" : "Turn On Bluetooth")
//                    .padding()
//            }
//
//            Text("Bluetooth is \(bluetoothManager.isBluetoothEnabled ? "enabled" : "disabled")")
//                .padding()
//
//            List(bluetoothManager.discoveredPeripherals, id: \.identifier) { peripheral in
//                HStack {
//                    Text(peripheral.name ?? "Unknown")
//                    Spacer()
//                    Button("Connect") {
//                        bluetoothManager.connect(to: peripheral)
//                    }
//                }
//            }
//        }
//    }
//}
