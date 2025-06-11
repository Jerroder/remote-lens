//
//  BluetoothManager.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-11.
//

import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    @Published var peripherals = [CBPeripheral]()
    private let relevantDeviceNames = ["EOSR6"]
    private var connectedPeripheral: CBPeripheral?
    private var handshakeCharacteristic: CBCharacteristic?
    // private var isReadyForHandshake = false

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
                let handshakeData = Data([0x01] + "iPhone 11 Pro".utf8)
                peripheral.writeValue(handshakeData, for: characteristic, type: .withResponse)
            } else if characteristic.uuid == CBUUID(string: "0001000a-0000-1000-0000-D8492FffA821") {
                print("Sending info to camera")
                handshakeCharacteristic = characteristic
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self.performHandshake(with: peripheral)
                }

            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateValueFor \(characteristic.uuid)")
        if characteristic.uuid == CBUUID(string: "00010006-0000-1000-0000-D8492FffA821") {
            if let value = characteristic.value, value == Data([0x02]) {
                print("User pressed OK. Ready to perform handshake.")
                // isReadyForHandshake = true
                performHandshake(with: peripheral)
                
                peripheral.setNotifyValue(true, for: characteristic)
            } else if let value = characteristic.value, value == Data([0x03]) {
                print("Handshake failed")
            }
        }
    }

    func performHandshake(with peripheral: CBPeripheral) {
        guard /* isReadyForHandshake,*/ let characteristic = handshakeCharacteristic else {
            print("Not ready for handshake or characteristic not found.")
            return
        }
        
        print("handshake")

        // Write device ID (16 random bytes)
        let deviceID = (0..<16).map { _ in UInt8.random(in: 0...255) }
        print("device ID: \(deviceID)")
        let deviceIDData = Data([0x03] + deviceID)
        peripheral.writeValue(deviceIDData, for: characteristic, type: .withResponse)

        // Write device name
        let deviceNameData = Data([0x04] + "iPhone 11 Pro".utf8)
        peripheral.writeValue(deviceNameData, for: characteristic, type: .withResponse)

        // Write device type (e.g., iOS)
        let deviceTypeData = Data([0x05, 0x01]) // 0x01 for iOS
        peripheral.writeValue(deviceTypeData, for: characteristic, type: .withResponse)

        // Finish handshake
        let finishHandshakeData = Data([0x01])
        peripheral.writeValue(finishHandshakeData, for: characteristic, type: .withResponse)
    }
}
