//
//  TextFieldToolbar.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-09-22.
//

import SwiftUI

struct TextFieldToolbarDone: ViewModifier {
    @Binding var isKeyboardShowing: Bool
    var isTextFieldFocused: FocusState<Bool>.Binding
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .safeAreaBar(edge: .bottom) {
                    if isKeyboardShowing {
                        HStack {
                            Spacer()
                            Button {
                                isTextFieldFocused.wrappedValue = false
                            } label: {
                                Image(systemName: "checkmark")
                                    .padding()
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.regular.interactive())
                            .padding(.horizontal, 15)
                            .padding(.bottom, 10)
                        }
                    }
                }
                .detectKeyboard(isKeyboardShowing: $isKeyboardShowing)
                .animation(.default, value: isKeyboardShowing)
        } else {
            content
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("done".localized(comment: "Done")) {
                            isTextFieldFocused.wrappedValue = false
                        }
                    }
                }
        }
    }
}

struct TextFieldToolbarDoneWithChevrons: ViewModifier {
    @Binding var isKeyboardShowing: Bool
    var focusedField: FocusState<Field?>
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .safeAreaBar(edge: .bottom) {
                    if isKeyboardShowing {
                        HStack {
                            Button(action: {
                                switch focusedField.wrappedValue {
                                case .waitBetweenPhotos:
                                    focusedField.wrappedValue = .numberOfPhotos
                                case .exposureTime:
                                    focusedField.wrappedValue = .waitBetweenPhotos
                                default:
                                    break
                                }
                            }) {
                                Image(systemName: "chevron.up")
                                    .padding()
                            }
                            .disabled(focusedField.wrappedValue == .numberOfPhotos)
                            
                            Button(action: {
                                switch focusedField.wrappedValue {
                                case .numberOfPhotos:
                                    focusedField.wrappedValue = .waitBetweenPhotos
                                case .waitBetweenPhotos:
                                    focusedField.wrappedValue = .exposureTime
                                default:
                                    break
                                }
                            }) {
                                Image(systemName: "chevron.down")
                                    .padding()
                            }
                            .disabled(focusedField.wrappedValue == .exposureTime)
                            
                            Spacer()
                            
                            Button {
                                focusedField.wrappedValue = nil
                            } label: {
                                Image(systemName: "checkmark")
                                    .padding()
                            }
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive())
                        .padding(.horizontal, 15)
                        .padding(.bottom, 10)
                    }
                }
                .detectKeyboard(isKeyboardShowing: $isKeyboardShowing)
                .animation(.default, value: isKeyboardShowing)
        } else {
            content
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("done".localized(comment: "Done")) {
                            focusedField.wrappedValue = nil
                        }
                    }
                }
        }
    }
}

extension View {
    func withTextFieldToolbarDone(isKeyboardShowing: Binding<Bool>, isTextFieldFocused: FocusState<Bool>.Binding) -> some View {
        self.modifier(
            TextFieldToolbarDone(isKeyboardShowing: isKeyboardShowing, isTextFieldFocused: isTextFieldFocused)
        )
    }
    
    func withTextFieldToolbarDoneWithChevrons(isKeyboardShowing: Binding<Bool>, focusedField: FocusState<Field?>) -> some View {
        self.modifier(
            TextFieldToolbarDoneWithChevrons(isKeyboardShowing: isKeyboardShowing, focusedField: focusedField)
        )
    }
}
