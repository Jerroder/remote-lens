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
    
    @State private var selectedOption: Int = UserDefaults.standard.integer(forKey: "selectedOption")
    @State private var showGeotagSheet: Bool = false
    
    var body: some View {
        NavigationStack {
            if bleManager.isConnected {
                TabView {
                    NavigationStack {
                        OneShotView(bleManager: bleManager, locationManager: locationManager, showGeotagSheet: $showGeotagSheet)
                    }
                    .tabItem {
                        Label("one_shot".localized(comment: "One Shot"), systemImage: "camera")
                    }
                    
                    NavigationStack {
                        IntervalometerView(bleManager: bleManager, locationManager: locationManager, showGeotagSheet: $showGeotagSheet)
                    }
                    .tabItem {
                        Label("intervalometer".localized(comment: "Intervalometer"), systemImage: "timer")
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
                .sheet(isPresented: $showGeotagSheet) {
                    GeotaggingView(bleManager: bleManager, locationManager: locationManager, selectedOption: $selectedOption, showGeotagSheet: $showGeotagSheet)
                }
            } else {
                ConnectionView(bleManager: bleManager)
            }
        } /* NavigationStack */
        .overlay(
            // Popup overlay
            Group {
                if bleManager.isPairing {
                    VStack {
                        Text("pairing_please_wait".localized(comment: "Pairing, please wait..."))
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemBackground).opacity(0.5))
                    .edgesIgnoringSafeArea(.all)
                }
            }
        )
        .alert("couldnt_connect_to_camera".localized(comment: "Couldn’t connect to the camera"), isPresented: $bleManager.warnRemoveFromiPhoneMenu) {
            Button("close".localized(comment: "Close"), role: .cancel) { }
        } message: {
            Text("remove_from_iphone_menu_text".localized(comment: "Please remove the camera from your iPhone's list"))
        }
        .alert("couldnt_connect_to_camera".localized(comment: "Couldn’t connect to the camera"), isPresented: $bleManager.warnRemoveFromCameraMenu) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("remove_from_camera_menu_text".localized(comment: "Please remove this iPhone from your camera’s list"))
        }
    }
}
