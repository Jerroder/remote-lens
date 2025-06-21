//
//  ContentView.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-10.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var bleManager = BluetoothManager()
    @StateObject private var locationManager = LocationManager()
    
    @State private var showGeotagSheet: Bool = false
    
    var body: some View {
        NavigationStack {
            if bleManager.isConnected {
                TabView {
                    OneShotView(bleManager: bleManager, locationManager: locationManager, showGeotagSheet: $showGeotagSheet).tabItem {
                        Image(systemName: "camera")
                        Text("one_shot".localized(comment: "One Shot"))
                    }
                    
                    IntervalometerView(bleManager: bleManager).tabItem {
                        Image(systemName: "timer")
                        Text("intervalometer".localized(comment: "Intervalometer"))
                    }
                }
                .navigationTitle(bleManager.connectedPeripheral?.name ?? "unknown_device".localized(comment: "Unknown Device"))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: {
                                bleManager.disconnect()
                            }) {
                                Label("disconnect".localized(comment: "Disconnect"), systemImage: "wifi.slash")
                            }
                            
                            Divider()
                            
                            Button(action: {
                                showGeotagSheet.toggle()
                            }) {
                                Label("geotagging".localized(comment: "Geotagging"), systemImage: "location")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            } else {
                ConnectionView(bleManager: bleManager)
            }
        }
    }
}
