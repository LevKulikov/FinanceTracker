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
    
    func setPreferredColorScheme(_ colorScheme: ColorScheme?)
    
    func getPreferredColorScheme() -> ColorScheme?
    
    func setFirstLaunch(_ isFirst: Bool)
    
    func isFirstLaunch() -> Bool
}

final class SettingsManager: SettingsManagerProtocol {
    //MARK: - Properties
    private let tagDefaultColorKey = "tagDefaultColorKey"
    private let appColorSchemeUserDefaultsKey = "appColorSchemeUserDefaultsKey"
    private let firstLaunchCkeckKey = "firstLaunchCkeckKey"
    
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
    
    func setPreferredColorScheme(_ colorScheme: ColorScheme?) {
        /*
         0 = light
         1 = dark
         nil = system color scheme
         */
        var colorSchemeIndex: Int?
        switch colorScheme {
        case .light:
            colorSchemeIndex = 0
        case .dark:
            colorSchemeIndex = 1
        case nil:
            colorSchemeIndex = nil
        case .some(_):
            colorSchemeIndex = nil
        }
        UserDefaults.standard.setValue(colorSchemeIndex, forKey: appColorSchemeUserDefaultsKey)
    }
    
    func getPreferredColorScheme() -> ColorScheme? {
        /*
         0 = light
         1 = dark
         nil = system color scheme
         */
        guard let colorNumber = UserDefaults.standard.value(forKey: appColorSchemeUserDefaultsKey) as? Int else { return nil }
        if colorNumber == 0 {
            return .light
        } else if colorNumber == 1 {
            return .dark
        } else {
            return nil
        }
    }
    
    func setFirstLaunch(_ isFirst: Bool) {
        UserDefaults.standard.set(isFirst, forKey: firstLaunchCkeckKey)
    }
    
    func isFirstLaunch() -> Bool {
        guard let isFirst = UserDefaults.standard.value(forKey: firstLaunchCkeckKey) as? Bool else { return true }
        return isFirst
    }
}
