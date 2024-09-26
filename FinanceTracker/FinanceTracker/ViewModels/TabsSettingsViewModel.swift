//
//  TabsSettingsViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 27.07.2024.
//

import Foundation
import SwiftUI

protocol TabsSettingsViewModelDelegate: AnyObject {
    func didSetSecondThirdTabsPosition(for tabsPositions: [TabViewType])
}

final class TabsSettingsViewModel: ObservableObject {
    //MARK: - Properties
    weak var delegate: (any TabsSettingsViewModelDelegate)?
    let numberOfTabsThatCanBeSet = 4
    
    //MARK: Published properties
    @MainActor @Published var changableTabs: [TabViewType]
    @MainActor @Published var settingsPosition: Int
    @MainActor @Published var changedSettingsPosition = false
    
    //MARK: Private properites
    private let dataManager: any DataManagerProtocol
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
        let savedTabs = dataManager.getThreeTabsArray()
        let canBeSet = Array(TabViewType.changableTabs.filter { !savedTabs.contains($0) })
        self._changableTabs = Published(wrappedValue: savedTabs + canBeSet)
        self._settingsPosition =  Published(wrappedValue: savedTabs.firstIndex(of: .settingsView) ?? 3) // 3 is default position of settings tab in tab bar
    }
    
    //MARK: - Methods
    @MainActor
    func moveTabs(indices: IndexSet, newOffset: Int) {
        var copyTabs = changableTabs
        copyTabs.move(fromOffsets: indices, toOffset: newOffset)
        // Prevent settings tab to be hidden
        guard copyTabs.last != .settingsView else {
            changableTabs = changableTabs
            return
        }
        
        changableTabs = copyTabs
        if copyTabs.firstIndex(of: .settingsView) == settingsPosition {
            saveTabs()
            withAnimation {
                changedSettingsPosition = false
            }
        } else {
            withAnimation {
                changedSettingsPosition = true
            }
        }
    }
    
    //MARK: Private methods
    @MainActor
    func saveTabs() {
        let toSave = Array(changableTabs.prefix(numberOfTabsThatCanBeSet))
        dataManager.setThreeTabsArray(toSave)
        delegate?.didSetSecondThirdTabsPosition(for: toSave)
    }
}
