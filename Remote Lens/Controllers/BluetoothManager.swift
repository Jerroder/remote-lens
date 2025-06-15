//
//  BluetoothManager.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-11.
//

import CoreBluetooth
import Foundation

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var peripherals: [CBPeripheral] = [CBPeripheral]()
    @Published var connectedPeripheral: CBPeripheral?
    @Published var isConnected: Bool = false
    @Published var isBluetoothEnabled: Bool = false

    private let handshakeService: String = "00010000-0000-1000-0000-D8492FffA821"
    private let startHandshakeUUID: String = "00010006-0000-1000-0000-D8492FffA821"
    private let endHandshakeUUID: String = "0001000a-0000-1000-0000-D8492FffA821"

    private let actuateShutterService: String = "00030000-0000-1000-0000-d8492fffa821"
    private let actuateShutterUUID: String = "00030030-0000-1000-0000-D8492FffA821"

    private let modeService: String = "00030000-0000-1000-0000-d8492fffa821"
    private let modeChangeUUID: String = "00030010-0000-1000-0000-d8492fffa821"
    private let modeNotifyUUID: String = "00030011-0000-1000-0000-d8492fffa821"
    private let playbackNavigationUUID: String = "00030020-0000-1000-0000-d8492fffa821"

    private let canonCompanyIdentifier: UInt16 = 0x01A9

    private var discoveredPeripheralIDs: Set<UUID> = Set<UUID>()
    private var centralManager: CBCentralManager!

    private var endHandshakeCharacteristic: CBCharacteristic?
    private var confirmHandshakeCharacteristic: CBCharacteristic?
    private var shutterCharacteristic: CBCharacteristic?
    private var modeChangeCharacteristic: CBCharacteristic?
    private var modeNotifyCharacteristic: CBCharacteristic?
    private var playbackNavigationCharacteristic: CBCharacteristic?

    private var scanTimer: Timer?
    private var shouldScan: Bool = true
    private var lastConnectedPeripheralUUID: UUID?
    private var isUserInitiatedDisconnect: Bool = false

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)

        if let uuidString = UserDefaults.standard.string(forKey: "lastConnectedPeripheralUUID") {
            lastConnectedPeripheralUUID = UUID(uuidString: uuidString)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            isBluetoothEnabled = true
            startScanningCycle()
        } else {
            isBluetoothEnabled = false
            print("Bluetooth is not available.")
        }
    }
    
    private func startScanningCycle() {
        guard shouldScan else {
            print("Scanning is disabled.")
            return
        }

        scanTimer?.invalidate()
        
        DispatchQueue.main.async {
            self.peripherals.removeAll()
            self.discoveredPeripheralIDs.removeAll()
        }

        centralManager.scanForPeripherals(withServices: nil, options: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.centralManager.stopScan()

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

                    if peripheral.identifier == lastConnectedPeripheralUUID && !isUserInitiatedDisconnect {
                        connect(to: peripheral)
                    }

                    return
                }
            }
        }
        
        print("Discovered non-Canon peripheral: \(peripheral.name ?? "Unknown")")
    }

    func connect(to peripheral: CBPeripheral) {
        shouldScan = false

        centralManager.stopScan()

        scanTimer?.invalidate()
        scanTimer = nil

        centralManager.connect(peripheral, options: nil)

        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self

        lastConnectedPeripheralUUID = peripheral.identifier
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.isConnected = true
        }
        
        peripheral.delegate = self

        let serviceUUIDs = [
                CBUUID(string: handshakeService),
                CBUUID(string: actuateShutterService),
                CBUUID(string: modeService)
            ]

        peripheral.discoverServices(serviceUUIDs)
        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: "lastConnectedPeripheralUUID")
        isUserInitiatedDisconnect = false
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

        print("Found service \(service.uuid)")
        for characteristic in characteristics {
            switch characteristic.uuid {
                case CBUUID(string: startHandshakeUUID):
                    print("Found characteristic for camera confirmation")
                    let handshakeData = Data([0x01] + "iPhone 11 Pro".utf8)
                    peripheral.writeValue(handshakeData, for: characteristic, type: .withResponse)

                    confirmHandshakeCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: confirmHandshakeCharacteristic!)

                case CBUUID(string: endHandshakeUUID):
                    print("Found characteristic for handshake")
                    endHandshakeCharacteristic = characteristic

                case CBUUID(string: actuateShutterUUID):
                    print("Found characteristic for shutter")
                    shutterCharacteristic = characteristic

                case CBUUID(string: modeChangeUUID):
                    print("Found characteristic for mode change")
                    modeChangeCharacteristic = characteristic

                case CBUUID(string: modeNotifyUUID):
                    print("Found characteristic for mode change notification")
                    modeNotifyCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: modeNotifyCharacteristic!)

                case CBUUID(string: playbackNavigationUUID):
                    print("Found characteristic for playback navigation")
                    playbackNavigationCharacteristic = characteristic

                default:
                    print("Found characteristic \(characteristic.uuid)")
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateValueForCharacteristic \(characteristic.uuid)")
        if characteristic.uuid == confirmHandshakeCharacteristic?.uuid {
            if let value = characteristic.value {
                if value == Data([0x02]) {
                    print("User pressed OK. Ready to perform handshake.")
                    performHandshake(with: peripheral)
                } else if value == Data([0x03]) {
                    print("User pressed Cancel.")
                    centralManager.cancelPeripheralConnection(peripheral)
                }
            }
        } else if characteristic.uuid == modeNotifyCharacteristic?.uuid {
            if let value = characteristic.value {
                if value == Data([0x04]) {
                    print("shooting mode")
                } else if value == Data([0x03]) {
                    print("playback mode")
                } else if value == Data([0x01]) {
                    print("sleep")
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral: \(peripheral.name ?? "Unknown")")
        
        DispatchQueue.main.async {
            self.isConnected = false
        }

        if !isUserInitiatedDisconnect {
            shouldScan = true
            startScanningCycle()
        }
    }

    func performHandshake(with peripheral: CBPeripheral) {
        guard let characteristic = endHandshakeCharacteristic else {
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
    
    func switchToPlayback() {
        guard let modeChangeCharacteristic = modeChangeCharacteristic else {
            print("Mode change characteristic not found.")
            return
        }

        let releaseData = Data([0x01])
        connectedPeripheral?.writeValue(releaseData, for: modeChangeCharacteristic, type: .withResponse)
    }
    
    func switchToShooting() {
        guard let modeChangeCharacteristic = modeChangeCharacteristic else {
            print("Mode change characteristic not found.")
            return
        }

        let releaseData = Data([0x02])
        connectedPeripheral?.writeValue(releaseData, for: modeChangeCharacteristic, type: .withResponse)
    }
    
    func disconnect() {
        guard let peripheral = connectedPeripheral else {
            print("No connected peripheral to disconnect from.")
            return
        }

        isUserInitiatedDisconnect = true
        centralManager.cancelPeripheralConnection(peripheral)
    }
}
