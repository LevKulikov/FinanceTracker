//
//  FTFacroty.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 11.06.2024.
//

import Foundation
import SwiftUI
import SwiftData

struct FTFactory {
    static let shared = FTFactory()
    
    
    
    private init() {}
    
    func createCustomTabView(dataManager: some DataManagerProtocol) -> some View {
        let viewModel = CustomTabViewModel(dataManager: dataManager)
        return CustomTabView(viewModel: viewModel)
    }
    
    func createSpendIncomeView(dataManager: some DataManagerProtocol, delegate: (some SpendIncomeViewModelDelegate)?, namespace: Namespace.ID) -> some View {
        let viewModel = SpendIncomeViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        
        return SpendIncomeView(viewModel: viewModel, namespace: namespace)
    }
    
    func createAddingSpendIcomeView(
        dataManager: some DataManagerProtocol,
        transactionType: TransactionsType,
        balanceAccount: BalanceAccount,
        forAction: Binding<ActionWithTransaction>,
        namespace: Namespace.ID,
        delegate: (some AddingSpendIcomeViewModelDelegate)?
    ) -> AnyView {
        let viewModel = AddingSpendIcomeViewModel(dataManager: dataManager, transactionsTypeSelected: transactionType, balanceAccount: balanceAccount)
        viewModel.delegate = delegate
        return AnyView(AddingSpendIcomeView(action: forAction, namespace: namespace, viewModel: viewModel))
    }
    
    func createAddingCategoryView(dataManager: some DataManagerProtocol, transactionType: TransactionsType, action: ActionWithCategory, delegate: (some AddingCategoryViewModelDelegate)?) -> AnyView {
        let viewModel = AddingCategoryViewModel(dataManager: dataManager, transactionType: transactionType, action: action)
        viewModel.delegate = delegate
        return AnyView(AddingCategoryView(viewModel: viewModel))
    }
    
    func createAddingBalanceAccauntView(dataManager: some DataManagerProtocol, action: ActionWithBalanceAccaunt, delegate: (some AddingBalanceAccountViewModelDelegate)?) -> AnyView {
        let viewModel = AddingBalanceAccountViewModel(dataManager: dataManager, action: action)
        viewModel.delegate = delegate
        return AnyView(AddingBalanceAccauntView(viewModel: viewModel))
    }
    
    func createStatisticsView(dataManager: some DataManagerProtocol) -> AnyView {
        let viewModel = StatisticsViewModel(dataManager: dataManager)
        return AnyView(StatisticsView(viewModel: viewModel))
    }
    
    func createSettingsView(dataManager: some DataManagerProtocol, delegate: (some SettingsViewModelDelegate)?) -> AnyView {
        let viewModel = SettingsViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        return AnyView(SettingsView(viewModel: viewModel))
    }
    
    func createBalanceAccountsView(dataManager: some DataManagerProtocol, delegate: (some BalanceAccountsViewModelDelegate)?) -> AnyView {
        let viewModel = BalanceAccountsViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        return AnyView(BalanceAccountsView(viewModel: viewModel))
    }
    
    func createCategoriesView(dataManager: some DataManagerProtocol, delegate: (some CategoriesViewModelDelegate)?) -> AnyView {
        let viewModel = CategoriesViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        return AnyView(CategoriesView(viewModel: viewModel))
    }
    
    func createTagsView(dataManager: some DataManagerProtocol, delegate: (some TagsViewModelDelegate)?) -> AnyView {
        let viewModel = TagsViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        return AnyView(TagsView(viewModel: viewModel))
    }
    
    func createAppearanceView(dataManager: some DataManagerProtocol) -> AnyView {
        let viewModel = AppearanceViewModel(dataManager: dataManager)
        return AnyView(AppearanceView(viewModel: viewModel))
    }
    
    func createManageDataView(dataManager: some DataManagerProtocol, delegate: (any ManageDataViewModelDelegate)?) -> AnyView {
        let viewModel = ManageDataViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        return AnyView(ManageDataView(viewModel: viewModel))
    }
    
    func createSearchView(dataManager: some DataManagerProtocol, delegate: (any SearchViewModelDelegate)?) -> AnyView {
        let viewModel = SearchViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        return AnyView(SearchView(viewModel: viewModel))
    }
}
