//
//  StringExtensions.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-13.
//

import SwiftUI

extension String {
    func localized(comment: String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }
}
