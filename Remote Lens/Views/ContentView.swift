//
//  ContentView.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-10.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var bleManager = BluetoothManager()

    var body: some View {
        NavigationView {
            List(bleManager.peripherals, id: \.identifier) { peripheral in
                Button(action: {
                    bleManager.connect(to: peripheral)
                }) {
                    Text(peripheral.name ?? "Unknown Device")
                }
            }
            .navigationTitle("BLE Devices")
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
