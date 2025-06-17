//
//  BluetoothDiscovery.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-10.
//

import CoreBluetooth
import SwiftUI

class BluetoothDiscovery: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject {
    @Published var isBluetoothEnabled = false
    @Published var discoveredPeripherals = [CBPeripheral]()
    @Published var connectedPeripheral: CBPeripheral?
    
    private var centralManager: CBCentralManager!
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            isBluetoothEnabled = true
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            isBluetoothEnabled = false
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
        }
    }
    
    func connect(to peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "unknown device")")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripheral = nil
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        print("Characteristics for service: \(service.uuid)")
        for characteristic in characteristics {
            printCharacteristicProperties(characteristic)
        }
    }
    
    func toggleBluetooth() {
        if centralManager.state == .poweredOn {
            centralManager.stopScan()
            centralManager = nil
        } else {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }
    
    func printCharacteristicProperties(_ characteristic: CBCharacteristic) {
        let properties = characteristic.properties
        var propertyNames: [String] = []
        
        if properties.contains(.broadcast) {
            propertyNames.append("broadcast")
        }
        if properties.contains(.read) {
            propertyNames.append("read")
        }
        if properties.contains(.writeWithoutResponse) {
            propertyNames.append("writeWithoutResponse")
        }
        if properties.contains(.write) {
            propertyNames.append("write")
        }
        if properties.contains(.notify) {
            propertyNames.append("notify")
        }
        if properties.contains(.indicate) {
            propertyNames.append("indicate")
        }
        if properties.contains(.authenticatedSignedWrites) {
            propertyNames.append("authenticatedSignedWrites")
        }
        if properties.contains(.extendedProperties) {
            propertyNames.append("extendedProperties")
        }
        if properties.contains(.notifyEncryptionRequired) {
            propertyNames.append("notifyEncryptionRequired")
        }
        if properties.contains(.indicateEncryptionRequired) {
            propertyNames.append("indicateEncryptionRequired")
        }
        
        print("  Discovered characteristic \(characteristic.uuid) properties: \(propertyNames.joined(separator: ", "))")
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
