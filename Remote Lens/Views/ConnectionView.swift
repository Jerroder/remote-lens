//
//  ConnectionView.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-13.
//

import SwiftUI

struct ConnectionView: View {
    @ObservedObject var bleManager: BluetoothManager

    var body: some View {
        VStack {
            if bleManager.peripherals.isEmpty {
                if bleManager.isBluetoothEnabled {
                    Text("no_devices_found".localized(comment: "No devices found"))
                } else {
                    Text("bluetooth_disabled".localized(comment: "Bluetooth is disabled"))
                }
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
