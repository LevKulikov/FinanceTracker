//
//  SettingsViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 18.06.2024.
//

import Foundation
import SwiftUI

final class SettingsViewModel: ObservableObject {
    //MARK: - Properties
    private let dataManager: any DataManagerProtocol
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
    }
    
    //MARK: - Methods
    
}
