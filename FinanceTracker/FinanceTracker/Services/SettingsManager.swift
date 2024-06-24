//
//  SettingsManager.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 24.06.2024.
//

import Foundation
import SwiftUI

protocol SettingsManagerProtocol: AnyObject {
    /// Sets tag default color to UserDefaults
    /// - Parameter color: color to save, nil = delete saved
    func setTagDefaultColor(_ color: Color?)
    
    func getTagDefaultColor() -> Color?
}

final class SettingsManager: SettingsManagerProtocol {
    //MARK: - Properties
    private let tagDefaultColorKey = "tagDefaultColorKey"
    
    //MARK: - Initializer
    init() {
        
    }
    
    //MARK: - Methods
    func setTagDefaultColor(_ color: Color?) {
        let uiColor: UIColor? = color == nil ? nil : UIColor(color!)
        UserDefaults.standard.set(uiColor?.encode(), forKey: tagDefaultColorKey)
    }
    
    func getTagDefaultColor() -> Color? {
        guard let data = UserDefaults.standard.data(forKey: tagDefaultColorKey) else { return nil }
        guard let uiColor = UIColor.color(data: data) else { return nil }
        return Color(uiColor: uiColor)
    }
}
