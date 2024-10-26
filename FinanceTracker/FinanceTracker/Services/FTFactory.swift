//
//  FTFacroty.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 11.06.2024.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
final class FTFactory {
    static let shared = FTFactory()
    
    //Instances to save view model for tabview, to not to create new one every time
    private var spendIncomeViewModel: SpendIncomeViewModel?
    private var searchViewModel: SearchViewModel?
    private var statisticsViewModel: StatisticsViewModel?
    private var budgetsViewModel: BudgetsViewModel?
    
    private init() {}
    
    func createWelcomeView(dataManager: some DataManagerProtocol, delegate: (some WelcomeViewModelDelegate)? = nil) -> AnyView {
        let viewModel = WelcomeViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        return AnyView(WelcomeView(viewModel: viewModel))
    }
    
    func createCustomTabView(dataManager: some DataManagerProtocol) -> some View {
        let viewModel = CustomTabViewModel(dataManager: dataManager)
        return CustomTabView(viewModel: viewModel)
    }
    
    func createSpendIncomeView(dataManager: some DataManagerProtocol, delegate: (some SpendIncomeViewModelDelegate)? = nil, namespace: Namespace.ID, strongReference: Bool = false, actionWithViewModel: ((SpendIncomeViewModel) -> Void)? = nil) -> AnyView {
        if strongReference, let spendIncomeViewModel {
            spendIncomeViewModel.delegate = delegate
            actionWithViewModel?(spendIncomeViewModel)
            return AnyView(SpendIncomeView(viewModel: spendIncomeViewModel, namespace: namespace))
        }
        
        let viewModel = SpendIncomeViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        if strongReference {
            spendIncomeViewModel = viewModel
        }
        actionWithViewModel?(viewModel)
        return AnyView(SpendIncomeView(viewModel: viewModel, namespace: namespace))
    }
    
    func createAddingSpendIcomeView(
        dataManager: some DataManagerProtocol,
        threadToUse: DataManager.DataThread,
        transactionType: TransactionsType,
        balanceAccount: BalanceAccount,
        forAction: Binding<ActionWithTransaction>,
        namespace: Namespace.ID,
        delegate: (some AddingSpendIcomeViewModelDelegate)? = nil
    ) -> AnyView {
        let viewModel = AddingSpendIcomeViewModel(dataManager: dataManager, use: threadToUse, transactionsTypeSelected: transactionType, balanceAccount: balanceAccount)
        viewModel.delegate = delegate
        return AnyView(AddingSpendIcomeView(action: forAction, namespace: namespace, viewModel: viewModel))
    }
    
    func createAddingCategoryView(dataManager: some DataManagerProtocol, transactionType: TransactionsType, action: ActionWithCategory, delegate: (some AddingCategoryViewModelDelegate)? = nil) -> AnyView {
        let viewModel = AddingCategoryViewModel(dataManager: dataManager, transactionType: transactionType, action: action)
        viewModel.delegate = delegate
        return AnyView(AddingCategoryView(viewModel: viewModel))
    }
    
    func createAddingBalanceAccauntView(dataManager: some DataManagerProtocol, action: ActionWithBalanceAccaunt, delegate: (some AddingBalanceAccountViewModelDelegate)? = nil) -> AnyView {
        let viewModel = AddingBalanceAccountViewModel(dataManager: dataManager, action: action)
        viewModel.delegate = delegate
        return AnyView(AddingBalanceAccauntView(viewModel: viewModel))
    }
    
    func createStatisticsView(dataManager: some DataManagerProtocol, delegate: (some StatisticsViewModelDelegate)? = nil, strongReference: Bool = false, actionWithViewModel: ((StatisticsViewModel) -> Void)? = nil) -> AnyView {
        if strongReference, let statisticsViewModel {
            actionWithViewModel?(statisticsViewModel)
            statisticsViewModel.delegate = delegate
            return AnyView(StatisticsView(viewModel: statisticsViewModel))
        }
        
        let viewModel = StatisticsViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        if strongReference {
            statisticsViewModel = viewModel
        }
        actionWithViewModel?(viewModel)
        return AnyView(StatisticsView(viewModel: viewModel))
    }
    
    func createSettingsView(dataManager: some DataManagerProtocol, delegate: (some SettingsViewModelDelegate)? = nil) -> AnyView {
        let viewModel = SettingsViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        return AnyView(SettingsView(viewModel: viewModel))
    }
    
    func createBalanceAccountsView(dataManager: some DataManagerProtocol, delegate: (some BalanceAccountsViewModelDelegate)? = nil) -> AnyView {
        let viewModel = BalanceAccountsViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        return AnyView(BalanceAccountsView(viewModel: viewModel))
    }
    
    func createCategoriesView(dataManager: some DataManagerProtocol, delegate: (some CategoriesViewModelDelegate)? = nil) -> AnyView {
        let viewModel = CategoriesViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        return AnyView(CategoriesView(viewModel: viewModel))
    }
    
    func createTagsView(dataManager: some DataManagerProtocol, delegate: (some TagsViewModelDelegate)? = nil) -> AnyView {
        let viewModel = TagsViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        return AnyView(TagsView(viewModel: viewModel))
    }
    
    func createAppearanceView(dataManager: some DataManagerProtocol, delegate: (some AppearanceViewModelDelegate)?) -> AnyView {
        let viewModel = AppearanceViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        return AnyView(AppearanceView(viewModel: viewModel))
    }
    
    func createManageDataView(dataManager: some DataManagerProtocol, delegate: (some ManageDataViewModelDelegate)? = nil) -> AnyView {
        let viewModel = ManageDataViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        return AnyView(ManageDataView(viewModel: viewModel))
    }
    
    func createSearchView(dataManager: some DataManagerProtocol, delegate: (some SearchViewModelDelegate)? = nil, strongReference: Bool = false, actionWithViewModel: ((SearchViewModel) -> Void)? = nil) -> AnyView {
        if strongReference, let searchViewModel {
            searchViewModel.delegate = delegate
            actionWithViewModel?(searchViewModel)
            return AnyView(SearchView(viewModel: searchViewModel))
        }
        
        let viewModel = SearchViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        if strongReference {
            searchViewModel = viewModel
        }
        actionWithViewModel?(viewModel)
        return AnyView(SearchView(viewModel: viewModel))
    }
    
    func createTransactionListView(dataManager: some DataManagerProtocol, transactions: [Transaction], title: String, threadToUse: DataManager.DataThread, delegate: (some TransactionListViewModelDelegate)? = nil) -> AnyView {
        let viewModel = TransactionListViewModel(dataManager: dataManager, transactions: transactions, title: title, threadToUse: threadToUse)
        viewModel.delegate = delegate
        return AnyView(TransactionListView(viewModel: viewModel))
    }
    
    func createTransactionListView<Content: View>(dataManager: some DataManagerProtocol, transactions: [Transaction], title: String, threadToUse: DataManager.DataThread, delegate: (some TransactionListViewModelDelegate)? = nil, topContent: @escaping ([Transaction]) -> Content) -> AnyView {
        let viewModel = TransactionListViewModel(dataManager: dataManager, transactions: transactions, title: title, threadToUse: threadToUse)
        viewModel.delegate = delegate
        return AnyView(TransactionListView(viewModel: viewModel, topContent: topContent))
    }
    
    func createBudgetsView(dataManager: some DataManagerProtocol,
                           delegate: (some BudgetsViewModelDelegate)? = nil,
                           strongReference: Bool = false,
                           actionWithViewModel: ((BudgetsViewModel) -> Void)? = nil) -> AnyView {
        if strongReference, let budgetsViewModel {
            budgetsViewModel.delegate = delegate
            actionWithViewModel?(budgetsViewModel)
            return AnyView(BudgetsView(viewModel: budgetsViewModel))
        }
        
        let viewModel = BudgetsViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        if strongReference {
            budgetsViewModel = viewModel
        }
        actionWithViewModel?(viewModel)
        return AnyView(BudgetsView(viewModel: viewModel))
    }
    
    func createAddingBudgetView(dataManager: some DataManagerProtocol, action: ActionWithBudget, delegate: (some AddingBudgetViewModelDelegate)? = nil) -> AnyView {
        let viewModel = AddingBudgetViewModel(action: action, dataManager: dataManager)
        viewModel.delegate = delegate
        return AnyView(AddingBudgetView(viewModel: viewModel))
    }
    
    func createNotificationsView(notificationManager: some NotificationManagerProtocol) -> AnyView {
        let viewModel = NotificationsViewModel(notificationManager: notificationManager)
        return AnyView(NotificationsView(viewModel: viewModel))
    }
    
    func createTabsSettingsView(dataManager: some DataManagerProtocol, delegate: (any TabsSettingsViewModelDelegate)? = nil) -> AnyView {
        let viewModel = TabsSettingsViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        return AnyView(TabsSettingsView(viewModel: viewModel))
    }
    
    func createProvidedStatisticsView(transactions: [Transaction], currency: String) -> AnyView {
        let viewModel = ProvidedStatisticsViewModel(transactions: transactions, currency: currency)
        return AnyView(ProvidedStatisticsView(viewModel: viewModel))
    }
    
    func createProvidedStatisticsView(transactions: [Transaction], currency: Currency) -> AnyView {
        let viewModel = ProvidedStatisticsViewModel(transactions: transactions, currency: currency)
        return AnyView(ProvidedStatisticsView(viewModel: viewModel))
    }
    
    func createTransfersView(dataManager: some DataManagerProtocol, delegate: (any TransfersViewModelDelegate)? = nil) -> AnyView {
        let viewModel = TransfersViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        return AnyView(TransfersView(viewModel: viewModel))
    }
    
    func createAddingTransferView(dataManager: some DataManagerProtocol, action: ActionWithTransferTransaction, delegate: (any AddingTransferViewModelDelegate)? = nil) -> AnyView {
        let viewModel = AddingTransferViewModel(dataManager: dataManager, action: action)
        viewModel.delegate = delegate
        return AnyView(AddingTransferView(viewModel: viewModel))
    }
}
