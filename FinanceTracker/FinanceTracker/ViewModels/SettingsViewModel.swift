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
    
    func didSetSecondThirdTabsPosition(for tabsPositions: [TabViewType])
}

enum SettingsSectionAndDataType {
    case categories
    case balanceAccounts
    case tags
    case transactions
    case appearance
    case data
    case budgets
    case notifications
}

final class SettingsViewModel: ObservableObject, @unchecked Sendable {
    //MARK: - Properties
    weak var delegate: (any SettingsViewModelDelegate)?
    let developerTelegramUsername = "k_lev_s"
    let developerEmail = "levkulikov.appdev@gmail.com"
    let codeSource = "https://github.com/LevKulikov/FinanceTracker.git"
    
    //MARK: Private props
    private let dataManager: any DataManagerProtocol
    
    //MARK: Published props
    
    @MainActor @Published var selectedSettings: SettingsSectionAndDataType? {
        didSet {
            if FTAppAssets.currentUserDevise == .phone {
                delegate?.didSelectSetting(selectedSettings)
            }
        }
    }
    
    @MainActor @Published private(set) var additionalTab: TabViewType?
    
    //MARK: - Initializer
    
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
        let savedTabs = dataManager.getSecondThirdTabsArray()
        let notSaved = TabViewType.changableTabs.filter { !savedTabs.contains($0) }
        self._additionalTab = Published(wrappedValue: notSaved.first)
    }
    
    //MARK: - Methods
    @MainActor
    func getBalanceAccountsView() -> some View {
        return FTFactory.shared.createBalanceAccountsView(dataManager: dataManager, delegate: self)
    }
    
    @MainActor
    func getCategoriesView() -> some View {
        return FTFactory.shared.createCategoriesView(dataManager: dataManager, delegate: self)
    }
    
    @MainActor
    func getTagsView() -> some View {
        return FTFactory.shared.createTagsView(dataManager: dataManager, delegate: self)
    }
    
    @MainActor
    func getAppearanceView() -> some View {
        return FTFactory.shared.createAppearanceView(dataManager: dataManager)
    }
    
    @MainActor
    func getManageDataView() -> some View {
        return FTFactory.shared.createManageDataView(dataManager: dataManager, delegate: self)
    }
    
    @MainActor
    func getBudgetsView() -> some View {
        return FTFactory.shared.createBudgetsView(dataManager: dataManager, delegate: self)
    }
    
    @MainActor
    func getAdditionalTabView() -> AnyView {
        guard let additionalTab else { return AnyView(EmptyView()) }
        switch additionalTab {
        case .searchView:
            return FTFactory.shared.createSearchView(dataManager: dataManager, delegate: self)
        case .statisticsView:
            return FTFactory.shared.createStatisticsView(dataManager: dataManager, delegate: self)
        case .budgetsView:
            return FTFactory.shared.createBudgetsView(dataManager: dataManager, delegate: self)
        default:
            return AnyView(EmptyView())
        }
    }
    
    @MainActor
    func getNotificationsView() -> some View {
        let notificationManager = NotificationManager()
        return FTFactory.shared.createNotificationsView(notificationManager: notificationManager)
    }
    
    @MainActor
    func getTabsSettingsView() -> some View {
        return FTFactory.shared.createTabsSettingsView(dataManager: dataManager, delegate: self)
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
    
    func didAddTag() {
        delegate?.didUpdateSettingsSection(.tags)
    }
    
    func didUpdatedTag() {
        delegate?.didUpdateSettingsSection(.tags)
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

//MARK: Extensions for BudgetsViewModelDelegate
extension SettingsViewModel: BudgetsViewModelDelegate {
    func didUpdateTransaction() {
        delegate?.didUpdateSettingsSection(.transactions)
    }
    
    func didAddBudget(_ budget: Budget) {
        
    }
    
    func didUpdateBudget(_ budget: Budget) {
        
    }
    
    func didDeleteBudget(_ budget: Budget) {
        
    }
}

extension SettingsViewModel: StatisticsViewModelDelegate {
    func showTabBar(_ show: Bool) {
        return
    }
    
    func didUpdatedTransactionsListFromStatistics() {
        delegate?.didUpdateSettingsSection(.transactions)
    }
}

extension SettingsViewModel: SearchViewModelDelegate {
    func didUpdatedTransactionsList() {
        delegate?.didUpdateSettingsSection(.transactions)
    }
    
    func hideTabBar(_ hide: Bool) {
        return
    }
}

//MARK: Extensions for TabsSettingsViewModelDelegate
extension SettingsViewModel: TabsSettingsViewModelDelegate {
    func didSetSecondThirdTabsPosition(for tabsPositions: [TabViewType]) {
        delegate?.didSetSecondThirdTabsPosition(for: tabsPositions)
        Task { @MainActor in
            let notSaved = TabViewType.changableTabs.filter { !tabsPositions.contains($0) }
            additionalTab = notSaved.first
        }
    }
}
