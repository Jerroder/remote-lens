//
//  TextFieldWithUnit.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-24.
//

import SwiftUI

// Source:
// https://medium.com/@shawky_91474/building-an-auto-expanding-textfield-with-dynamic-unit-display-in-swiftui-bd3621b10573
// https://web.archive.org/web/20250624171027/https://medium.com/@shawky_91474/building-an-auto-expanding-textfield-with-dynamic-unit-display-in-swiftui-bd3621b10573
private struct SetWidthAccordingToText: ViewModifier {
    let value: Double
    @State private var textWidth: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .frame(width: textWidth)
            .background(
                Text(String(value))
                    .fixedSize()
                    .hidden()
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.width
                    } action: { width in
                        self.textWidth = width
                    }
                
            )
    }
}

private extension View {
    func setWidthAccordingTo(value: Double) -> some View {
        modifier(SetWidthAccordingToText(value: value))
    }
}

struct TextFieldWithUnit: View {
    @Binding var value: Double
    @Binding var unit: Unit

    var body: some View {
        HStack(spacing: 2) {
            TextField("0.0", value: $value, format: .number)
                .setWidthAccordingTo(value: value)

            Text(unit.symbol)
        }
    }
}
