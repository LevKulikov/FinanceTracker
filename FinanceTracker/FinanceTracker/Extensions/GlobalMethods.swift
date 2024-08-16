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


/// Get the current directory
/// - Returns: the Current directory in NSString
func getDocumentsDirectory() -> NSString {
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    let documentsDirectory = paths[0]
    return documentsDirectory as NSString
}
