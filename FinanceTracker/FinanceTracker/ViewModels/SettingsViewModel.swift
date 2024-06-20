//
//  SettingsViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 18.06.2024.
//

import Foundation
import SwiftUI

protocol SettingsViewModelDelegate: AnyObject {
    func didSelectSetting(_ setting: SettingsSection?)
}

enum SettingsSection {
    case categories
    case balanceAccounts
    case tags
    case appearance
    case data
}

final class SettingsViewModel: ObservableObject {
    //MARK: - Properties
    weak var delegate: (any SettingsViewModelDelegate)?
    let developerTelegramUsername = "k_lev_s"
    let developerEmail = "levkulikov.appdev@gmail.com"
    
    //MARK: Private props
    private let dataManager: any DataManagerProtocol
    
    //MARK: Published props
    @Published var selectedSettings: SettingsSection? {
        didSet {
            delegate?.didSelectSetting(selectedSettings)
        }
    }
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
    }
    
    //MARK: - Methods
    
}
