//
//  DataManager.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 25.05.2024.
//

import Foundation
import SwiftData

protocol DataManagerProtocol: AnyObject {
    @MainActor
    func save() throws
    
    @MainActor
    func deleteTransaction(_ transaction: Transaction)
    
    /// Moves transaction with selected balance account to default one and then deletes selected balance account (BA). If provided BA is default, then methods returns and does not anything. If default BA is not set, method will return
    /// - Parameter balanceAccount: balance account to delete, should not be the same as default one, otherwise nothing will be done
    @MainActor
    func deleteBalanceAccount(_ balanceAccount: BalanceAccount)
    
    
    /// Deletes selected balance account (BA) with binded transactions. If provided BA is default, then methods returns and does not anything. If default BA is not set, method will return
    /// - Parameter balanceAccount: balance account to delete, should not be the same as default one, otherwise nothing will be done
    @MainActor
    func deleteBalanceAccountWithTransactions(_ balanceAccount: BalanceAccount)
    
    @MainActor
    func insert<T>(_ model: T) where T : PersistentModel
    
    @MainActor
    func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] where T : PersistentModel
    
    func setDefaultBalanceAccount(_ balanceAccount: BalanceAccount)
    
    func getDefaultBalanceAccount() -> BalanceAccount?
}

final class DataManager: DataManagerProtocol {
    //MARK: - Properties
    private let container: ModelContainer
    private let defaultBalanceAccountIdKey = "defaultBalanceAccountIdKey"
    private var balanceAccounts: [BalanceAccount] = []
    
    //MARK: - Init
    init(container: ModelContainer) {
        self.container = container
        fetchBalanceAccounts()
    }
    
    //MARK: - Methods
    func save() throws {
        try container.mainContext.save()
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        container.mainContext.delete(transaction)
    }
    
    func deleteBalanceAccount(_ balanceAccount: BalanceAccount) {
        guard let defaultBA = getDefaultBalanceAccount() else { return }
        guard balanceAccount != defaultBA else { return }
        
        let fetchTransactionDescriptor = FetchDescriptor<Transaction>()
        do {
            // Get transactions with selected balance account
            let allTransactions = try fetch(fetchTransactionDescriptor)
            let filtered = allTransactions.filter { $0.balanceAccount == balanceAccount }
            // Replace selected balance account to default one for each transaction
            filtered.forEach { $0.setBalanceAccount(defaultBA) }
            // Delete selected balance account and save changes
            container.mainContext.delete(balanceAccount)
            try save()
        } catch {
            print(error)
            return
        }
    }
    
    func deleteBalanceAccountWithTransactions(_ balanceAccount: BalanceAccount) {
        guard let defaultBA = getDefaultBalanceAccount() else { return }
        guard balanceAccount != defaultBA else { return }
        
        let fetchTransactionDescriptor = FetchDescriptor<Transaction>()
        do {
            // Get transactions with selected balance account
            let allTransactions = try fetch(fetchTransactionDescriptor)
            let filtered = allTransactions.filter { $0.balanceAccount == balanceAccount }
            // Delete filtered transactions
            filtered.forEach { deleteTransaction($0) }
            // Delete selected balance account and save changes
            container.mainContext.delete(balanceAccount)
            try save()
        } catch {
            print(error)
            return
        }
    }
    
    func insert<T>(_ model: T) where T : PersistentModel {
        container.mainContext.insert(model)
    }
    
    func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] where T : PersistentModel {
        let fetchedData = try container.mainContext.fetch(descriptor)
        if let balanceAccountsData = fetchedData as? [BalanceAccount] {
            balanceAccounts = balanceAccountsData
        }
        return fetchedData
    }
    
    func setDefaultBalanceAccount(_ balanceAccount: BalanceAccount) {
        UserDefaults.standard.set(balanceAccount.id, forKey: defaultBalanceAccountIdKey)
    }
    
    func getDefaultBalanceAccount() -> BalanceAccount? {
        guard let baId = UserDefaults.standard.string(forKey: defaultBalanceAccountIdKey) else { return nil }
        return balanceAccounts.first { $0.id == baId }
    }
    
    //MARK: Private methods
    private func fetchBalanceAccounts() {
        let descriptor = FetchDescriptor<BalanceAccount>()
        Task {
            let data = try await fetch(descriptor)
            balanceAccounts = data
        }
    }
}
