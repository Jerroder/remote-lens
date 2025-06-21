//
//  IntervalometerView.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-13.
//

import SwiftUI

struct IntervalometerView: View {
    private enum Field: Int, CaseIterable {
        case numberOfPhotos, waitBetweenPhotos, exposureTime
    }
    
    @ObservedObject var bleManager: BluetoothManager
    @ObservedObject var locationManager: LocationManager
    @Binding var showGeotagSheet: Bool
    
    @State private var numberOfPhotos: Int = UserDefaults.standard.integer(forKey: "numberOfPhotos")
    @State private var waitBetweenPhotos: Double = UserDefaults.standard.double(forKey: "waitBetweenPhotos")
    @State private var exposureTime: Double = UserDefaults.standard.double(forKey: "exposureTime")
    @State private var isRunning: Bool = false
    @State private var showingInfoAlert: Bool = false
    @State private var selectedOption: Int = UserDefaults.standard.integer(forKey: "selectedOption")
    
    @FocusState private var focusedField: Field?
    
    private let numberOfPhotosKey: String = "numberOfPhotos"
    private let waitBetweenPhotosKey: String = "waitBetweenPhotos"
    private let exposureTimeKey: String = "exposureTime"
    
    var body: some View {
        Form {
            HStack {
                Text("number_of_photos".localized(comment: "Number of photos"))
                    .frame(width: 170, alignment: .leading)
                TextField("0", value: $numberOfPhotos, format: .number)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .numberOfPhotos)
                    .onChange(of: numberOfPhotos) { _, _ in
                        UserDefaults.standard.set(numberOfPhotos, forKey: numberOfPhotosKey)
                    }
            }
            
            HStack {
                Text("wait_between_photos".localized(comment: "Wait between photos"))
                    .frame(width: 170, alignment: .leading)
                TextField("0.0", value: $waitBetweenPhotos, format: .number)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .waitBetweenPhotos)
                    .onChange(of: waitBetweenPhotos) { _, _ in
                        UserDefaults.standard.set(waitBetweenPhotos, forKey: waitBetweenPhotosKey)
                    }
            }
            
            HStack {
                Text("exposure_time".localized(comment: "Exposure time"))
                    .frame(width: 170, alignment: .leading)
                TextField("0.0", value: $exposureTime, format: .number)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .exposureTime)
                    .onChange(of: exposureTime) { _, _ in
                        UserDefaults.standard.set(exposureTime, forKey: exposureTimeKey)
                    }
                
                Button(action: {
                    showingInfoAlert = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(Color(UIColor.systemGray))
                }
                .buttonStyle(PlainButtonStyle())
                .alert(isPresented: $showingInfoAlert) {
                    Alert(
                        title: Text("Info"),
                        message: Text("exposure_info_text".localized(comment: "If exposure is set to 0")),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            
            HStack {
                Spacer()
                
                Button(action: {
                    if self.isRunning {
                        self.isRunning = false
                    } else {
                        self.isRunning = true
                        self.startIntervalometer()
                    }
                    focusedField = nil
                }) {
                    Text(isRunning ? "stop".localized(comment: "Stop") : "start".localized(comment: "Start"))
                }
                
                Spacer()
            }
        } /* Form */
        .scrollDisabled(true)
        .toolbar { // Throws an error for some reason, but it works
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("done".localized(comment: "Done")) {
                    focusedField = nil
                }
            }
        }
        .sheet(isPresented: $showGeotagSheet) {
            GeotaggingView(bleManager: bleManager, locationManager: locationManager, selectedOption: $selectedOption, showGeotagSheet: $showGeotagSheet)
        }
    } /* View */
    
    private func startIntervalometer() {
        DispatchQueue.global(qos: .userInitiated).async {
            for i in 0..<numberOfPhotos {
                if !self.isRunning {
                    break
                }
                
                DispatchQueue.main.async {
                    self.bleManager.takePhoto()
                }
                
                if exposureTime > 0 {
                    Thread.sleep(forTimeInterval: exposureTime)
                    DispatchQueue.main.async {
                        self.bleManager.takePhoto()
                    }
                }
                
                if i < numberOfPhotos - 1 && self.isRunning {
                    Thread.sleep(forTimeInterval: waitBetweenPhotos)
                }
            }
            
            DispatchQueue.main.async {
                self.isRunning = false
            }
        }
    }
}
