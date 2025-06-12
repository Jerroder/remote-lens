//
//  BluetoothManager.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-11.
//

import CoreBluetooth
import Foundation

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var peripherals = [CBPeripheral]()
    @Published var isConnected = false
    @Published var connectedPeripheral: CBPeripheral?

    private let handshakeService = "00010000-0000-1000-0000-D8492FffA821"
    private let startHandshakeCharacteristic = "00010006-0000-1000-0000-D8492FffA821"
    private let endHandshakeCharacteristic = "0001000a-0000-1000-0000-D8492FffA821"
    private let actuateShutterService = "00030000-0000-1000-0000-d8492fffa821"
    private let actuateShutterCharacteristic = "00030030-0000-1000-0000-D8492FffA821"
    private let canonCompanyIdentifier = 0x01A9

    private var discoveredPeripheralIDs = Set<UUID>()
    private var centralManager: CBCentralManager!
    private var handshakeCharacteristic: CBCharacteristic?
    private var confirmationCharacteristic: CBCharacteristic?
    private var shutterCharacteristic: CBCharacteristic?
    private var scanTimer: Timer?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanningCycle()
        } else {
            print("Bluetooth is not available.")
        }
    }
    
    private func startScanningCycle() {
        // Invalidate any existing timer to ensure only one cycle is active
        scanTimer?.invalidate()

        // Start scanning
        centralManager.scanForPeripherals(withServices: nil, options: nil)

        // Stop scanning after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.centralManager.stopScan()

            // Schedule the next scan cycle after 5 seconds
            self?.scanTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                self?.startScanningCycle()
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard !discoveredPeripheralIDs.contains(peripheral.identifier) else {
            print("Peripheral discovered twice: \(peripheral.name ?? "Unknown")")
            return
        }

        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            if manufacturerData.count >= 2 {
                let companyIdentifier = manufacturerData.subdata(in: 0..<2).withUnsafeBytes { $0.load(as: UInt16.self) }
                if companyIdentifier == canonCompanyIdentifier {
                    discoveredPeripheralIDs.insert(peripheral.identifier)
                    DispatchQueue.main.async {
                        self.peripherals.append(peripheral)
                    }
                    return
                }
            }
        }
        
        print("Discovered non-Canon peripheral: \(peripheral.name ?? "Unknown")")
    }

    func connect(to peripheral: CBPeripheral) {
        centralManager.stopScan()
        scanTimer?.invalidate()
        centralManager.connect(peripheral, options: nil)
        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.isConnected = true
        }
        
        peripheral.delegate = self

        let serviceUUIDs = [
                CBUUID(string: handshakeService),
                CBUUID(string: actuateShutterService)
            ]

        peripheral.discoverServices(serviceUUIDs)
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
            if characteristic.uuid == CBUUID(string: startHandshakeCharacteristic) {
                print("Found characteristic for camera confirmation")
                let handshakeData = Data([0x01] + "iPhone 11 Pro".utf8) // @TODO: replace with prompted name
                peripheral.writeValue(handshakeData, for: characteristic, type: .withResponse)

                confirmationCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: confirmationCharacteristic!)
            } else if characteristic.uuid == CBUUID(string: endHandshakeCharacteristic) {
                print("Found characteristic for handshake")
                handshakeCharacteristic = characteristic
            } else if characteristic.uuid == CBUUID(string: actuateShutterCharacteristic) {
                print("Found characteristic for shutter")
                shutterCharacteristic = characteristic
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateValueFor \(characteristic.uuid)")
        if characteristic.uuid == confirmationCharacteristic?.uuid {
            if let value = characteristic.value {
                if value == Data([0x02]) {
                    print("User pressed OK. Ready to perform handshake.")
                    performHandshake(with: peripheral)
                } else if value == Data([0x03]) {
                    print("User pressed Cancel.")
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral: \(peripheral.name ?? "Unknown")")
        
        DispatchQueue.main.async {
            self.isConnected = false // Update connection state
        }

        startScanningCycle()
    }

    func performHandshake(with peripheral: CBPeripheral) {
        guard let characteristic = handshakeCharacteristic else {
            print("Handshake characteristic not found.")
            return
        }
        
        print("Performing handshake...")

        // Write device ID (16 random bytes)
        let deviceID = (0..<16).map { _ in UInt8.random(in: 0...255) }
        print("device ID: \(deviceID)")
        let deviceIDData = Data([0x03] + deviceID)
        peripheral.writeValue(deviceIDData, for: characteristic, type: .withResponse)

        // Write device name
        let deviceNameData = Data([0x04] + "iPhone 11 Pro".utf8) // @TODO: replace with prompted name
        peripheral.writeValue(deviceNameData, for: characteristic, type: .withResponse)

        // Write device type (e.g., iOS)
        let deviceTypeData = Data([0x05, 0x01]) // 0x01 for iOS
        peripheral.writeValue(deviceTypeData, for: characteristic, type: .withResponse)

        // Finish handshake
        let finishHandshakeData = Data([0x01])
        peripheral.writeValue(finishHandshakeData, for: characteristic, type: .withResponse)
    }
    
    func pressShutter() {
        guard let shutterCharacteristic = shutterCharacteristic else {
            print("Shutter characteristic not found.")
            return
        }

        let pressData = Data([0x00, 0x01])
        connectedPeripheral?.writeValue(pressData, for: shutterCharacteristic, type: .withResponse)
    }

    func releaseShutter() {
        guard let shutterCharacteristic = shutterCharacteristic else {
            print("Shutter characteristic not found.")
            return
        }

        let releaseData = Data([0x00, 0x02])
        connectedPeripheral?.writeValue(releaseData, for: shutterCharacteristic, type: .withResponse)
    }

    func takePhoto() {
        pressShutter()
        releaseShutter()
    }
}
