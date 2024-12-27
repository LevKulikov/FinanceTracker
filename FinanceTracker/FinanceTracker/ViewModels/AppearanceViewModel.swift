//
//  AppearanceViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 25.06.2024.
//

import Foundation
import SwiftUI

protocol AppearanceViewModelDelegate: AnyObject {
    func didSetShowAddButtonFromEvetyTab(_ show: Bool)
}

final class AppearanceViewModel: ObservableObject {
    //MARK: - Properties
    weak var delegate: AppearanceViewModelDelegate?
    private let settingsManager: any SettingsAdapterProtocol
    
    //MARK: Published props
    @MainActor @Published var showAddButtonFromEvetyTab: Bool {
        didSet {
            settingsManager.showAddButtonFromEvetyTab(showAddButtonFromEvetyTab)
            delegate?.didSetShowAddButtonFromEvetyTab(showAddButtonFromEvetyTab)
        }
    }
    @MainActor @Published var stayAtAddingViewAfterAdd: Bool {
        didSet {
            settingsManager.stayAtAddingViewAfterAdd(stayAtAddingViewAfterAdd)
        }
    }
    @MainActor @Published private(set) var preferredColorScheme: ColorScheme?
    @MainActor @Published private(set) var firstThreeTabs: [TabViewType]
    
    //MARK: - Initializer
    init(settingsManager: some SettingsAdapterProtocol) {
        self.settingsManager = settingsManager
        self._showAddButtonFromEvetyTab = Published(wrappedValue: settingsManager.showAddButtonFromEvetyTab())
        self._stayAtAddingViewAfterAdd = Published(wrappedValue: settingsManager.stayAtAddingViewAfterAdd())
        self._preferredColorScheme = Published(wrappedValue: settingsManager.getPreferredColorScheme())
        self._firstThreeTabs = Published(wrappedValue: settingsManager.getThreeTabsArray())
    }
    
    //MARK: - Methods
    @MainActor
    func setPreferredColorScheme(_ colorScheme: ColorScheme?) {
        settingsManager.setPreferredColorScheme(colorScheme)
        withAnimation {
            preferredColorScheme = colorScheme
        }
    }
}
