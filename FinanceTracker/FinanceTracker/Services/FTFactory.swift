//
//  FTFacroty.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 11.06.2024.
//

import Foundation
import SwiftUI
import SwiftData

final class FTFactory {
    static let shared = FTFactory()
    
    //Instances to save view model for tabview, to not to create new one every time
    private var spendIncomeViewModel: SpendIncomeViewModel?
    private var searchViewModel: SearchViewModel?
    private var statisticsViewModel: StatisticsViewModel?
    
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
    
    func createSpendIncomeView(dataManager: some DataManagerProtocol, delegate: (some SpendIncomeViewModelDelegate)? = nil, namespace: Namespace.ID, actionWithViewModel: ((SpendIncomeViewModel) -> Void)? = nil) -> AnyView {
        if let spendIncomeViewModel {
            spendIncomeViewModel.delegate = delegate
            actionWithViewModel?(spendIncomeViewModel)
            return AnyView(SpendIncomeView(viewModel: spendIncomeViewModel, namespace: namespace))
        }
        
        let viewModel = SpendIncomeViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        spendIncomeViewModel = viewModel
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
    
    @MainActor
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
    
    func createStatisticsView(dataManager: some DataManagerProtocol, delegate: (some StatisticsViewModelDelegate)? = nil, actionWithViewModel: ((StatisticsViewModel) -> Void)? = nil) -> AnyView {
        if let statisticsViewModel {
            actionWithViewModel?(statisticsViewModel)
            statisticsViewModel.delegate = delegate
            return AnyView(StatisticsView(viewModel: statisticsViewModel))
        }
        
        let viewModel = StatisticsViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        statisticsViewModel = viewModel
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
    
    func createAppearanceView(dataManager: some DataManagerProtocol) -> AnyView {
        let viewModel = AppearanceViewModel(dataManager: dataManager)
        return AnyView(AppearanceView(viewModel: viewModel))
    }
    
    func createManageDataView(dataManager: some DataManagerProtocol, delegate: (some ManageDataViewModelDelegate)? = nil) -> AnyView {
        let viewModel = ManageDataViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        return AnyView(ManageDataView(viewModel: viewModel))
    }
    
    func createSearchView(dataManager: some DataManagerProtocol, delegate: (some SearchViewModelDelegate)? = nil, actionWithViewModel: ((SearchViewModel) -> Void)? = nil) -> AnyView {
        if let searchViewModel {
            searchViewModel.delegate = delegate
            actionWithViewModel?(searchViewModel)
            return AnyView(SearchView(viewModel: searchViewModel))
        }
        
        let viewModel = SearchViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        searchViewModel = viewModel
        actionWithViewModel?(viewModel)
        return AnyView(SearchView(viewModel: viewModel))
    }
    
    func createTransactionListView(dataManager: some DataManagerProtocol, transactions: [Transaction], title: String, threadToUse: DataManager.DataThread, delegate: (some TransactionListViewModelDelegate)? = nil) -> AnyView {
        let viewModel = TransactionListViewModel(dataManager: dataManager, transactions: transactions, title: title, threadToUse: threadToUse)
        viewModel.delegate = delegate
        return AnyView(TransactionListView(viewModel: viewModel))
    }
    
    func createBudgetsView(dataManager: some DataManagerProtocol,
                           delegate: (some BudgetsViewModelDelegate)? = nil,
                           actionWithViewModel: ((BudgetsViewModel) -> Void)? = nil) -> AnyView {
        let viewModel = BudgetsViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
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
}
