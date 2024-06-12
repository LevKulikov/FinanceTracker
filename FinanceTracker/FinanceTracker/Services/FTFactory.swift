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
    static func createCustomTabView(dataManager: some DataManagerProtocol) -> some View {
        let viewModel = CustomTabViewModel(dataManager: dataManager)
        return CustomTabView(viewModel: viewModel)
    }
    
    static func createSpendIncomeView(dataManager: some DataManagerProtocol, delegate: (some SpendIncomeViewModelDelegate)?, namespace: Namespace.ID) -> some View {
        let viewModel = SpendIncomeViewModel(dataManager: dataManager)
        viewModel.delegate = delegate
        
        return SpendIncomeView(viewModel: viewModel, namespace: namespace)
    }
    
    static func createAddingSpendIcomeView(
        dataManager: some DataManagerProtocol,
        transactionType: TransactionsType,
        forAction: Binding<ActionWithTransaction>,
        namespace: Namespace.ID,
        delegate: (some AddingSpendIcomeViewModelDelegate)?
    ) -> AnyView {
        let viewModel = AddingSpendIcomeViewModel(dataManager: dataManager, transactionsTypeSelected: transactionType)
        viewModel.delegate = delegate
        return AnyView(AddingSpendIcomeView(action: forAction, namespace: namespace, viewModel: viewModel))
    }
    
    static func createAddingCategoryView(dataManager: some DataManagerProtocol, transactionType: TransactionsType, action: ActionWithCategory, delegate: (some AddingCategoryViewModelDelegate)?) -> AnyView {
        let viewModel = AddingCategoryViewModel(dataManager: dataManager, transactionType: transactionType, action: action)
        viewModel.delegate = delegate
        return AnyView(AddingCategoryView(viewModel: viewModel))
    }
    
    static func createAddingBalanceAccauntView(dataManager: some DataManagerProtocol, action: ActionWithBalanceAccaunt, delegate: (some AddingBalanceAccountViewModelDelegate)?) -> AnyView {
        let viewModel = AddingBalanceAccountViewModel(dataManager: dataManager, action: action)
        viewModel.delegate = delegate
        return AnyView(AddingBalanceAccauntView(viewModel: viewModel))
    }
}