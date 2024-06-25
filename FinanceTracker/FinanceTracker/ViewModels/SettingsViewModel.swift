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
    
    func didUpdateSettingsSection(_ section: SettingsSection)
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
    func getBalanceAccountsView() -> some View {
        return FTFactory.createBalanceAccountsView(dataManager: dataManager, delegate: self)
    }
    
    func getCategoriesView() -> some View {
        return FTFactory.createCategoriesView(dataManager: dataManager, delegate: self)
    }
    
    func getTagsView() -> some View {
        return FTFactory.createTagsView(dataManager: dataManager, delegate: self)
    }
}

//MARK: - Extensions
//MARK: Extension for BalanceAccountsViewModelDelegate
extension SettingsViewModel: BalanceAccountsViewModelDelegate {
    func didUpdatedBalanceAccountsList() {
        delegate?.didUpdateSettingsSection(.balanceAccounts)
    }
    
    func didDeleteBalanceAccount() {
        delegate?.didUpdateSettingsSection(.data)
    }
}

//MARK: Extension for CategoriesViewModelDelegate
extension SettingsViewModel: CategoriesViewModelDelegate {
    func didUpdateCategoryList() {
        delegate?.didUpdateSettingsSection(.categories)
    }
    
    func didDeleteCategory() {
        delegate?.didUpdateSettingsSection(.data)
    }
}

//MARK: Extension for TagsViewModelDelegate
extension SettingsViewModel: TagsViewModelDelegate {
    
}
