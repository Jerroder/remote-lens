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
                        if bleManager.requiresPairing {
                            bleManager.requestConnection(to: peripheral)
                        } else {
                            bleManager.connect(to: peripheral)
                        }
                    }) {
                        Text(peripheral.name ?? "unknown_device".localized(comment: "Unknown Device"))
                    }
                }
            }
        }
        .navigationTitle("canon_cameras".localized(comment: "Canon Cameras"))
        .alert("do_you_want_to_connect_with".localized(with: "\(bleManager.selectedPeripheral?.name ?? "this device")", comment: "Do you want to connect with (...)?"), isPresented: $bleManager.showPairingAlert) {
            Button("connect".localized(comment: "Connect"), role: nil) {
                bleManager.userDidConfirmConnection()
            }
            Button("cancel".localized(comment: "Cancel"), role: .cancel) {
                bleManager.userDidCancelConnection()
            }
        } message: {
            Text("device_name_will_be_sent_to_camera".localized(with: "\(bleManager.iphoneName)", comment: "The name of your device (...) will be sent to the camera"))
        }
    }
}
