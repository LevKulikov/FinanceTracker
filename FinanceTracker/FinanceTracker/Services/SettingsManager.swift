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
    
    func setThreeTabsArray(_ tabsArray: [TabViewType])
    
    func getThreeTabsArray() -> [TabViewType]
    
    func isLightWeightStatistics() -> Bool
    
    func setLightWeightStatistics(_ isLight: Bool)
    
    func showAddButtonFromEvetyTab() -> Bool
    
    func showAddButtonFromEvetyTab(_ show: Bool)
}

final class SettingsManager: SettingsManagerProtocol {
    //MARK: - Properties
    private let tagDefaultColorKey = "tagDefaultColorKey"
    private let appColorSchemeUserDefaultsKey = "appColorSchemeUserDefaultsKey"
    private let firstLaunchCkeckKey = "firstLaunchCkeckKey"
    private let tabsArrayKey = "tabsArrayKey"
    private let lightWeightStatisticsKey = "lightWeightStatisticsKey"
    private let showAddButtonFromEvetyTabKey = "showAddButtonFromEvetyTabKey"
    
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
    
    func getThreeTabsArray() -> [TabViewType] {
        guard let stringArray = UserDefaults.standard.stringArray(forKey: tabsArrayKey) else {
            return [.spendIncomeView, .statisticsView, .searchView, .settingsView]
        }
        let tabsArray = stringArray.compactMap { TabViewType(rawValue: $0) }
        guard tabsArray.count > 3 else {
            return [.spendIncomeView, .statisticsView, .searchView, .settingsView]
        }
        return tabsArray
    }
    
    func setThreeTabsArray(_ tabsArray: [TabViewType]) {
        let stringArray = tabsArray.map { $0.rawValue }
        UserDefaults.standard.set(stringArray, forKey: tabsArrayKey)
    }
    
    func isLightWeightStatistics() -> Bool {
        UserDefaults.standard.bool(forKey: lightWeightStatisticsKey)
    }
    
    func setLightWeightStatistics(_ isLight: Bool) {
        UserDefaults.standard.set(isLight, forKey: lightWeightStatisticsKey)
    }
    
    func showAddButtonFromEvetyTab() -> Bool {
        UserDefaults.standard.bool(forKey: showAddButtonFromEvetyTabKey)
    }
    
    func showAddButtonFromEvetyTab(_ show: Bool) {
        UserDefaults.standard.set(show, forKey: showAddButtonFromEvetyTabKey)
    }
}
