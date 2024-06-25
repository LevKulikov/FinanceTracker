//
//  GlobalMethods.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 19.06.2024.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import UIKit

func copyAsPlainText(_ value: String) {
    let clipboard = UIPasteboard.general
    clipboard.setValue(value, forPasteboardType: UTType.plainText.identifier)
}
