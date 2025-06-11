//
//  BluetoothHandshake.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-10.
//

import CoreBluetooth
import SwiftUI

class BluetoothHandshake: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var peripherals = [CBPeripheral]()

    private let relevantDeviceNames = ["EOSR6"]

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var handshakeCharacteristic: CBCharacteristic?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            print("Bluetooth is not available.")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "unknown device")")
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let peripheralName = peripheral.name, relevantDeviceNames.contains(peripheralName) {
            if !peripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                DispatchQueue.main.async {
                    self.peripherals.append(peripheral)
                }
            }
        }
    }

    func connect(to peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: "00010000-0000-1000-0000-D8492FffA821")])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            print(characteristic.uuid)
            if characteristic.uuid == CBUUID(string: "00010006-0000-1000-0000-D8492FffA821") {
                print("Starting handshake")
                let handshakeData = Data([0x01] + "iPhone 11".utf8)
                peripheral.writeValue(handshakeData, for: characteristic, type: .withResponse)
            } else if characteristic.uuid == CBUUID(string: "0001000a-0000-1000-0000-D8492FffA821") {
                print("Sending info to camera")
                handshakeCharacteristic = characteristic
                // performHandshake(with: peripheral)
            }
        }
    }

    func performHandshake(with peripheral: CBPeripheral) {
        guard let characteristic = handshakeCharacteristic else { return }
        
        print("handshake")

        // Write device ID (16 random bytes)
        let deviceID = (0..<16).map { _ in UInt8.random(in: 0...255) }
        print("device ID: \(deviceID)")
        let deviceIDData = Data([0x03] + deviceID)
        peripheral.writeValue(deviceIDData, for: characteristic, type: .withResponse)

        // Write device name
        let deviceNameData = Data([0x04] + "YourDeviceName".utf8)
        peripheral.writeValue(deviceNameData, for: characteristic, type: .withResponse)

        // Write device type (e.g., iOS)
        let deviceTypeData = Data([0x05, 0x01]) // 0x01 for iOS
        peripheral.writeValue(deviceTypeData, for: characteristic, type: .withResponse)

        // Finish handshake
        let finishHandshakeData = Data([0x01])
        peripheral.writeValue(finishHandshakeData, for: characteristic, type: .withResponse)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == CBUUID(string: "00010006-0000-1000-0000-D8492FffA821") {
            if let value = characteristic.value {
                if value == Data([0x02]) {
                    print("Handshake successful")
                } else if value == Data([0x03]) {
                    print("Handshake failed")
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error writing value for characteristic \(characteristic.uuid): \(error.localizedDescription)")
            return
        }
        
        print("Successfully wrote value for characteristic \(characteristic.uuid)")
        
        // You can add additional logic here based on the characteristic UUID or other criteria
        if characteristic.uuid == CBUUID(string: "0001000A-0000-1000-0000-D8492FffA821") {
            // Handle specific logic for this characteristic if needed
        }
    }
}
