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
    @State private var unit: Unit = Unit(symbol: "s")
    
    @FocusState private var focusedField: Field?
    
    var body: some View {
        Form {
            HStack {
                Text("number_of_photos".localized(comment: "Number of photos"))
                    .frame(width: 170, alignment: .leading)
                TextField("0", value: $numberOfPhotos, format: .number)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .numberOfPhotos)
                    .onChange(of: numberOfPhotos) { _, _ in
                        UserDefaults.standard.set(numberOfPhotos, forKey: "numberOfPhotos")
                    }
            }
            
            HStack {
                Text("wait_between_photos".localized(comment: "Wait between photos"))
                    .frame(width: 170, alignment: .leading)
                TextFieldWithUnit(value: $waitBetweenPhotos, unit: $unit)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .waitBetweenPhotos)
                    .onChange(of: waitBetweenPhotos) { _, _ in
                        UserDefaults.standard.set(waitBetweenPhotos, forKey: "waitBetweenPhotos")
                    }
            }
            
            HStack {
                Text("exposure_time".localized(comment: "Exposure time"))
                    .frame(width: 170, alignment: .leading)
                TextFieldWithUnit(value: $exposureTime, unit: $unit)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .exposureTime)
                    .onChange(of: exposureTime) { _, _ in
                        UserDefaults.standard.set(exposureTime, forKey: "exposureTime")
                    }
                
                Spacer()
                
                Button(action: {
                    showingInfoAlert = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color(UIColor.systemGray))
                }
                .buttonStyle(PlainButtonStyle())
                .alert("Info", isPresented: $showingInfoAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("exposure_info_text".localized(comment: "If exposure is set to 0"))
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
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Button(action: {
                        switch focusedField {
                        case .waitBetweenPhotos:
                            focusedField = .numberOfPhotos
                        case .exposureTime:
                            focusedField = .waitBetweenPhotos
                        default:
                            break
                        }
                    }) {
                        Image(systemName: "chevron.up")
                            .padding()
                    }
                    .disabled(focusedField == .numberOfPhotos)
                    
                    Button(action: {
                        switch focusedField {
                        case .numberOfPhotos:
                            focusedField = .waitBetweenPhotos
                        case .waitBetweenPhotos:
                            focusedField = .exposureTime
                        default:
                            break
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .padding()
                    }
                    .disabled(focusedField == .exposureTime)
                    
                    Spacer()
                    
                    Button {
                        focusedField = nil
                    } label: {
                        Image(systemName: "checkmark")
                            .padding()
                    }
                }
            }
        }
        .sensoryFeedback(trigger: isRunning) { oldValue, newValue in
            let flex = newValue ? SensoryFeedback.Flexibility.soft : SensoryFeedback.Flexibility.solid
            return .impact(flexibility: flex, intensity: 1.0)
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
