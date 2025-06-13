//
//  ContentView.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-10.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var bleManager = BluetoothManager()

    var body: some View {
        NavigationStack {
            if bleManager.isConnected {
                TabView {
                    OneShotView(bleManager: bleManager).tabItem {
                        Image(systemName: "camera")
                        Text("one_shot".localized(comment: "One Shot"))
                    }
                    
                    IntervalometerView().tabItem {
                        Image(systemName: "timer")
                        Text("intervalometer".localized(comment: "Intervalometer"))
                    }
                }
                .navigationTitle(bleManager.connectedPeripheral?.name ?? "unknown_device".localized(comment: "Unknown Device"))
            } else {
                ConnectionView(bleManager: bleManager)
            }
        }
    }
}
