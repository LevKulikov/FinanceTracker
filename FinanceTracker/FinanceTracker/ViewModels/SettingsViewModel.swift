//
//  SettingsViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 18.06.2024.
//

import Foundation
import SwiftUI

protocol SettingsViewModelDelegate: AnyObject {
    func didSelectSetting(_ setting: SettingsSectionAndDataType?)
    
    func didUpdateSettingsSection(_ section: SettingsSectionAndDataType)
}

enum SettingsSectionAndDataType {
    case categories
    case balanceAccounts
    case tags
    case transactions
    case appearance
    case data
}

final class SettingsViewModel: ObservableObject {
    //MARK: - Properties
    weak var delegate: (any SettingsViewModelDelegate)?
    let developerTelegramUsername = "k_lev_s"
    let developerEmail = "levkulikov.appdev@gmail.com"
    let codeSource = "https://github.com/LevKulikov/FinanceTracker.git"
    
    //MARK: Private props
    private let dataManager: any DataManagerProtocol
    private let userIdiom = FTAppAssets.currentUserDevise
    
    //MARK: Published props
    @Published var selectedSettings: SettingsSectionAndDataType? {
        didSet {
            if userIdiom == .phone {
                delegate?.didSelectSetting(selectedSettings)
            }
        }
    }
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
    }
    
    //MARK: - Methods
    func getBalanceAccountsView() -> some View {
        return FTFactory.shared.createBalanceAccountsView(dataManager: dataManager, delegate: self)
    }
    
    func getCategoriesView() -> some View {
        return FTFactory.shared.createCategoriesView(dataManager: dataManager, delegate: self)
    }
    
    func getTagsView() -> some View {
        return FTFactory.shared.createTagsView(dataManager: dataManager, delegate: self)
    }
    
    func getAppearanceView() -> some View {
        return FTFactory.shared.createAppearanceView(dataManager: dataManager)
    }
    
    func getManageDataView() -> some View {
        return FTFactory.shared.createManageDataView(dataManager: dataManager, delegate: self)
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
    func didDeleteTag() {
        delegate?.didUpdateSettingsSection(.tags)
    }
    
    func didDeleteTagWithTransactions() {
        delegate?.didUpdateSettingsSection(.data)
    }
}

//MARK: Extension for ManageDataViewModelDelegate
extension SettingsViewModel: ManageDataViewModelDelegate {
    func didDeleteAllTransactions() {
        delegate?.didUpdateSettingsSection(.data)
    }
    
    func didDeleteAllData() {
        delegate?.didUpdateSettingsSection(.data)
    }
}
