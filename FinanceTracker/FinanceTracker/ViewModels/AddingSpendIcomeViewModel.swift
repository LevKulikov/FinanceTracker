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
    var action: ActionWithTransaction = .none {
        didSet {
            switch action {
            case .none, .add:
                break
                //TODO: set default values to balanceAccount
            case .update(let transaction):
                transactionToUpdate = transaction
                setTransactionPropertiesToViewModel(transaction: transaction)
            }
            setDateArray()
        }
    }
    var transactionToUpdate: Transaction?
    @Published var availableCategories: [Category] = []
    @Published var availableTags: [Tag] = []
    @Published var availableBalanceAccounts: [BalanceAccount] = []
    @Published var threeDatesArray: [Date] = []
    
    //MARK: Transaction Props
    @Published var transactionsTypeSelected: TransactionsType = .spending {
        didSet {
            delegate?.transactionsTypeReselected(to: transactionsTypeSelected)
            category = nil
            Task {
                await fetchCategories()
            }
        }
    }
    @Published var comment: String = ""
    @Published var valueString: String = ""
    @Published var value: Float = 0
    @Published var date: Date = .now {
        didSet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.setDateArray()
            }
        }
    }
    @Published var balanceAccount: BalanceAccount = .emptyBalanceAccount
    @Published var category: Category?
    @Published var tags: [Tag] = []
    
    //MARK: Initializer
    init(dataManager: some DataManagerProtocol, transactionsTypeSelected: TransactionsType) {
        self.dataManager = dataManager
        self._transactionsTypeSelected = Published(wrappedValue: transactionsTypeSelected)
        fetchAllData()
    }
    
    //MARK: Methods
    func addRemoveTag(_ tag: Tag) {
        if tags.contains(tag) {
            withAnimation {
                tags.removeAll {
                    $0 == tag
                }
            }
        } else {
            withAnimation {
                tags.append(tag)
            }
        }
    }
    
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
            availableCategories = fetchedCategories
        }
    }
    
    @MainActor
    private func fetchTags(errorHandler: ((Error) -> Void)? = nil) async {
        guard let fetchedTags: [Tag] = await fetch() else {
            errorHandler?(FetchErrors.unableToFetchTags)
            return
        }
        
        withAnimation(.snappy) {
            availableTags = fetchedTags
        }
    }
    
    @MainActor
    private func fetchBalanceAccounts(errorHandler: ((Error) -> Void)? = nil) async {
        guard let fetchedBalanceAccounts: [BalanceAccount] = await fetch(sortWithString: \.name) else {
            errorHandler?(FetchErrors.unableToFetchBalanceAccounts)
            return
        }
        
        withAnimation(.snappy) {
            availableBalanceAccounts = fetchedBalanceAccounts
        }
    }
    
    private func fetch<T>(withPredicate: Predicate<T>? = nil, sortWithString keyPath: KeyPath<T, String>? = nil) async -> [T]? where T: PersistentModel {
        let descriptor = FetchDescriptor<T>(
            predicate: withPredicate,
            sortBy: keyPath == nil ? [] : [SortDescriptor(keyPath!)]
        )
        
        do {
            var fetchedItems = try await dataManager.fetch(descriptor)
            if keyPath == nil {
                fetchedItems.reverse()
            }
            return fetchedItems
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    private func setTransactionPropertiesToViewModel(transaction: Transaction) {
        if let trType = transaction.type, trType != transactionsTypeSelected {
            transactionsTypeSelected = trType
        }
        comment = transaction.comment
        value = transaction.value
        valueString = String(value).replacing(".", with: ",")
        date = transaction.date
        balanceAccount = transaction.balanceAccount
        category = transaction.category
        tags = transaction.tags
    }
    
    private func setDateArray() {
        let calendar = Calendar.current
        var array: [Date] = []
        if calendar.startOfDay(for: date) == calendar.startOfDay(for: .now) {
            guard let prepreviousDay = calendar.date(byAdding: .day, value: -2, to: date),
                  let previousDay = calendar.date(byAdding: .day, value: -1, to: date) else {
                return
            }
            
            array = [prepreviousDay, previousDay, date]
        } else {
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: date),
                  let nextDay = calendar.date(byAdding: .day, value: 1, to: date) else {
                return
            }
            
            array = [previousDay, date, nextDay]
        }
        
        withAnimation {
            threeDatesArray = array
        }
    }
}
