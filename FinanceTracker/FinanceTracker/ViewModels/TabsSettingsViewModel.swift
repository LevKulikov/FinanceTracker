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
    
    //MARK: Published properties
    
    //MARK: Private properites
    private let dataManager: any DataManagerProtocol
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
    }
    
    //MARK: - Methods
    
    //MARK: Private methods
}
