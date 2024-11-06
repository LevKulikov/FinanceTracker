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
    
    func didUpdateSettingsSectionData(_ section: SettingsSectionAndDataType)
    
    func didAddSettingsSectionData(_ section: SettingsSectionAndDataType)
    
    func didDeleteSettingsSectionData(_ section: SettingsSectionAndDataType)
    
    func didDeleteSettingsSectionDataWithTransactions(_ section: SettingsSectionAndDataType)
    
    func didSetSecondThirdTabsPosition(for tabsPositions: [TabViewType])
}

enum SettingsSectionAndDataType: Hashable {
    case categories(Category?)
    case balanceAccounts(BalanceAccount?)
    case tags(Tag?)
    case transactions(Transaction?)
    case transfers(TransferTransaction?)
    case appearance
    case data
    case budgets(Budget?)
    case notifications
}

final class SettingsViewModel: ObservableObject, @unchecked Sendable {
    //MARK: - Properties
    weak var delegate: (any SettingsViewModelDelegate)?
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
    
    @ViewBuilder
    private var spendIncomeViewPlaceholder: some View {
        ContentUnavailableView("Sorry, this tab is only available from the bottom menu", systemImage: "hand.raised", description: Text("If you want to open it, please reorder the tabs in Settings. To do so, press \"\(Image(systemName: "ellipsis.rectangle")) Reorder tabs\""))
    }
    
    //MARK: - Initializer
    
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
        let savedTabs = dataManager.getThreeTabsArray()
        let notSaved = TabViewType.changableTabs.filter { !savedTabs.contains($0) }
        self._additionalTab = Published(wrappedValue: notSaved.first)
    }
    
    //MARK: - Methods
    @MainActor
    func getTransfersView() -> some View {
        return FTFactory.shared.createTransfersView(dataManager: dataManager, delegate: self)
    }
    
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
        return FTFactory.shared.createAppearanceView(dataManager: dataManager, delegate: self)
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
        case .spendIncomeView:
            return AnyView(spendIncomeViewPlaceholder)
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
    
    @MainActor
    func getDeveloperToolView() -> some View {
        let viewModel = DeveloperToolViewModel(dataManager: dataManager)
        return DeveloperToolView(viewModel: viewModel)
    }
}

//MARK: - Extensions
//MARK: Extension for BalanceAccountsViewModelDelegate
extension SettingsViewModel: BalanceAccountsViewModelDelegate {
    func didAddBalanceAccount(_ balanceAccount: BalanceAccount, from tabView: TabViewType) {
        delegate?.didAddSettingsSectionData(.balanceAccounts(balanceAccount))
    }
    
    func didUpdateBalanceAccount(_ balanceAccount: BalanceAccount, from tabView: TabViewType) {
        delegate?.didUpdateSettingsSectionData(.balanceAccounts(balanceAccount))
    }
    
    func didDeleteBalanceAccount(_ balanceAccount: BalanceAccount, from tabView: TabViewType) {
        delegate?.didDeleteSettingsSectionData(.balanceAccounts(balanceAccount))
    }
    
    func didDeleteBalanceAccountWithTransactions(_ balanceAccount: BalanceAccount) {
        delegate?.didDeleteSettingsSectionDataWithTransactions(.balanceAccounts(balanceAccount))
    }
    
    func didAddTransferTransaction(_ transferTransaction: TransferTransaction, from tabView: TabViewType) {
        delegate?.didAddSettingsSectionData(.transfers(transferTransaction))
    }
    
    func didUpdateTransferTransaction(_ transferTransaction: TransferTransaction, from tabView: TabViewType) {
        delegate?.didUpdateSettingsSectionData(.transfers(transferTransaction))
    }
    
    func didDeleteTransferTransaction(_ transferTransaction: TransferTransaction, from tabView: TabViewType) {
        delegate?.didDeleteSettingsSectionData(.transfers(transferTransaction))
    }
}

extension SettingsViewModel: TransfersViewModelDelegate {
    func didAddTransferTransaction(_ transfer: TransferTransaction) {
        delegate?.didAddSettingsSectionData(.transfers(transfer))
    }
    
    func didUpdateTransferTransaction(_ transfer: TransferTransaction) {
        delegate?.didUpdateSettingsSectionData(.transfers(transfer))
    }
    
    func didDeleteTransferTransaction(_ transfer: TransferTransaction) {
        delegate?.didDeleteSettingsSectionData(.transfers(transfer))
    }
}

//MARK: Extension for CategoriesViewModelDelegate
extension SettingsViewModel: CategoriesViewModelDelegate {
    func didAddCategory(_ category: Category, from tabView: TabViewType) {
        delegate?.didAddSettingsSectionData(.categories(category))
    }
    
    func didUpdateCategory(_ category: Category, from tabView: TabViewType) {
        delegate?.didUpdateSettingsSectionData(.categories(category))
    }
    
    func didDeleteCategory(_ category: Category, from tabView: TabViewType) {
        delegate?.didDeleteSettingsSectionData(.categories(category))
    }
    
    func didDeleteCategoryWithTransactions(_ category: Category) {
        delegate?.didDeleteSettingsSectionDataWithTransactions(.categories(category))
    }
}

//MARK: Extension for TagsViewModelDelegate
extension SettingsViewModel: TagsViewModelDelegate {
    func didAddTag(_ tag: Tag, from tabView: TabViewType) {
        delegate?.didAddSettingsSectionData(.tags(tag))
    }
    
    func didUpdatedTag(_ tag: Tag, from tabView: TabViewType) {
        delegate?.didUpdateSettingsSectionData(.tags(tag))
    }
    
    func didDeleteTag(_ tag: Tag, from tabView: TabViewType) {
        delegate?.didDeleteSettingsSectionData(.tags(tag))
    }
    
    func didDeleteTagWithTransactions(_ tag: Tag) {
        delegate?.didDeleteSettingsSectionDataWithTransactions(.tags(tag))
    }
}

//MARK: Extension for ManageDataViewModelDelegate
extension SettingsViewModel: ManageDataViewModelDelegate {
    func didDeleteAllTransactions() {
        delegate?.didUpdateSettingsSectionData(.data)
    }
    
    func didDeleteAllData() {
        delegate?.didUpdateSettingsSectionData(.data)
    }
    
    func didDeleteAndImportNewData() {
        delegate?.didUpdateSettingsSectionData(.data)
    }
}

//MARK: Extensions for BudgetsViewModelDelegate
extension SettingsViewModel: BudgetsViewModelDelegate {
    func didAddBudget(_ budget: Budget) {
        delegate?.didAddSettingsSectionData(.budgets(budget))
    }
    
    func didUpdateBudget(_ budget: Budget) {
        delegate?.didUpdateSettingsSectionData(.budgets(budget))
    }
    
    func didDeleteBudget(_ budget: Budget) {
        delegate?.didDeleteSettingsSectionData(.budgets(budget))
    }
}

extension SettingsViewModel: TransactionManipulationDelegate {
    func didAddTransaction(_ transaction: Transaction, from tabView: TabViewType) {
        delegate?.didAddSettingsSectionData(.transactions(transaction))
    }
    
    func didUpdateTransaction(_ transaction: Transaction, from tabView: TabViewType) {
        delegate?.didUpdateSettingsSectionData(.transactions(transaction))
    }
    
    func didDeleteTransaction(_ transaction: Transaction?, from tabView: TabViewType) {
        delegate?.didDeleteSettingsSectionData(.transactions(transaction))
    }
}

extension SettingsViewModel: StatisticsViewModelDelegate {
    func didDeleteTagWithTransactions(_ tag: Tag, from tabView: TabViewType) {
        delegate?.didDeleteSettingsSectionDataWithTransactions(.tags(tag))
    }
    
    func showTabBar(_ show: Bool) {
        return
    }
}

extension SettingsViewModel: SearchViewModelDelegate {
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

//MARK: Extensions for AppearanceViewModelDelegate
extension SettingsViewModel: AppearanceViewModelDelegate {
    func didSetShowAddButtonFromEvetyTab(_ show: Bool) {
        delegate?.didUpdateSettingsSectionData(.appearance)
    }
}

