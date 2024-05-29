//
//  AddingSpendIcomeViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 29.05.2024.
//

import Foundation
import SwiftData
import SwiftUI

protocol AddingSpendIcomeViewModelDelegate: AnyObject {
    func addedNewTransaction(_ transaction: Transaction)
    func updateTransaction(_ transaction: Transaction)
    func transactionsTypeReselected(to newType: TransactionsType)
}

enum FetchErrors: Error {
    case unableToFetchCategories
    case unableToFetchTags
    case unableToFetchBalanceAccounts
}

final class AddingSpendIcomeViewModel: ObservableObject {
    //MARK: Properties
    private let dataManager: any DataManagerProtocol
    weak var delegate: (any AddingSpendIcomeViewModelDelegate)?
    @Published var transactionsTypeSelected: TransactionsType = .spending {
        didSet {
            delegate?.transactionsTypeReselected(to: transactionsTypeSelected)
            Task {
                await fetchCategories()
            }
        }
    }
    @Published var categories: [Category] = []
    @Published var tags: [Tag] = []
    @Published var balanceAccounts: [BalanceAccount] = []
    
    //MARK: Initializer
    init(dataManager: some DataManagerProtocol, transactionsTypeSelected: TransactionsType) {
        self.dataManager = dataManager
        self._transactionsTypeSelected = Published(wrappedValue: transactionsTypeSelected)
        fetchAllData()
    }
    
    //MARK: Methods
    private func fetchAllData(errorHandler: ((Error) -> Void)? = nil) {
        Task {
            await fetchCategories(errorHandler: errorHandler)
            await fetchTags(errorHandler: errorHandler)
            await fetchBalanceAccounts(errorHandler: errorHandler)
        }
    }
    
    @MainActor
    private func fetchCategories(errorHandler: ((Error) -> Void)? = nil) async {
        // It is needed to prevent Predicate type convertion error (cannot reference an object property inside of a Predicate)
        let rawValue = transactionsTypeSelected.rawValue
        
        let predicate = #Predicate<Category> {
            $0.typeRawValue == rawValue
        }
        
        guard let fetchedCategories = await fetch(withPredicate: predicate) else {
            errorHandler?(FetchErrors.unableToFetchCategories)
            return
        }
        
        withAnimation(.snappy) {
            categories = fetchedCategories
        }
    }
    
    @MainActor
    private func fetchTags(errorHandler: ((Error) -> Void)? = nil) async {
        guard let fetchedTags: [Tag] = await fetch(withPredicate: nil) else {
            errorHandler?(FetchErrors.unableToFetchTags)
            return
        }
        
        withAnimation(.snappy) {
            tags = fetchedTags
        }
    }
    
    @MainActor
    private func fetchBalanceAccounts(errorHandler: ((Error) -> Void)? = nil) async {
        guard let fetchedBalanceAccounts: [BalanceAccount] = await fetch(withPredicate: nil) else {
            errorHandler?(FetchErrors.unableToFetchBalanceAccounts)
            return
        }
        
        withAnimation(.snappy) {
            balanceAccounts = fetchedBalanceAccounts
        }
    }
    
    private func fetch<T>(withPredicate: Predicate<T>?) async -> [T]? where T: PersistentModel, T: Named {
        let descriptor = FetchDescriptor<T>(
            predicate: withPredicate,
            sortBy: [SortDescriptor<T>(\.name)]
        )
        
        do {
            let fetchedItems = try await dataManager.fetch(descriptor)
            return fetchedItems
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}
