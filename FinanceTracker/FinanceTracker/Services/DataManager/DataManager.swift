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
