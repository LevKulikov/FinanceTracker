//
//  DataManager.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 25.05.2024.
//

import Foundation
import SwiftData
import SwiftUI

protocol DataManagerProtocol: AnyObject {
    var tagDefaultColor: Color? { get set }
    var isFirstLaunch: Bool { get set }
    
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
    
    /// Deletes selected category and moves binded transactions to the second provided one
    /// - Parameters:
    ///   - category: category to delete
    ///   - replacingCategory: category to move transaction to
    @MainActor
    func deleteCategory(_ category: Category, moveTransactionsTo replacingCategory: Category) async
    
    /// Deletes selected category and all binded to it transactions
    /// - Parameter category: category to delete
    @MainActor
    func deleteCategoryWithTransactions(_ category: Category) async
    
    @MainActor
    func deleteTag(_ tag: Tag) async
    
    @MainActor
    func deleteTagWithTransactions(_ tag: Tag) async
    
    @MainActor
    func deleteAllTransactions() async
    
    @MainActor
    func deleteAllStoredData() async
    
    @MainActor
    func insert<T>(_ model: T) where T : PersistentModel
    
    @MainActor
    func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] where T : PersistentModel
    
    func setDefaultBalanceAccount(_ balanceAccount: BalanceAccount)
    
    func getDefaultBalanceAccount() -> BalanceAccount?
    
    func setPreferredColorScheme(_ colorScheme: ColorScheme?)
    
    func getPreferredColorScheme() -> ColorScheme?
    
    @MainActor
    func saveDefaultCategories()
}

final class DataManager: DataManagerProtocol, ObservableObject {
    //MARK: - Properties
    private let container: ModelContainer
    private let settingsManager: any SettingsManagerProtocol
    private let defaultBalanceAccountIdKey = "defaultBalanceAccountIdKey"
    private var balanceAccounts: [BalanceAccount] = []
    private let defaultSpendingCategories: [Category] = [
        .init(type: .spending, name: "Groceries", iconName: "shopping-cart", color: .blue),
        .init(type: .spending, name: "Сafes", iconName: "003-cutlery", color: .yellow),
        .init(type: .spending, name: "Transport", iconName: "car", color: .orange),
        .init(type: .spending, name: "Entertainments", iconName: "001-gamepad", color: .indigo),
        .init(type: .spending, name: "Education", iconName: "016-book", color: .purple),
        .init(type: .spending, name: "Health", iconName: "018-heart", color: .red),
        .init(type: .spending, name: "Gifts", iconName: "031-gift", color: .mint),
        .init(type: .spending, name: "Home", iconName: "home", color: .brown),
        .init(type: .spending, name: "Family", iconName: "010-love-3", color: .pink),
        .init(type: .spending, name: "Other", iconName: "047-upload", color: .red),
    ]
    private let defaultIncomeCategories: [Category] = [
        .init(type: .income, name: "Gifts", iconName: "031-gift", color: .mint),
        .init(type: .income, name: "Salary", iconName: "1-economy-004-economy", color: .green),
        .init(type: .income, name: "Interest", iconName: "1-economy-007-bank", color: .purple),
        .init(type: .income, name: "Other", iconName: "download", color: .green),
    ]
    
    var tagDefaultColor: Color? {
        get {
            settingsManager.getTagDefaultColor()
        }
        
        set {
            settingsManager.setTagDefaultColor(newValue)
        }
    }
    
    var isFirstLaunch: Bool {
        get {
            settingsManager.isFirstLaunch()
        }
        set {
            settingsManager.setFirstLaunch(newValue)
        }
    }
    
    //MARK: Only for DataManager properties
    @Published private(set) var preferredColorScheme: ColorScheme?
    
    //MARK: - Init
    init(container: ModelContainer) {
        self.container = container
        self.settingsManager = SettingsManager()
        self.preferredColorScheme = settingsManager.getPreferredColorScheme()
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
    
    func deleteCategory(_ category: Category, moveTransactionsTo replacingCategory: Category) async {
        let fetchTransactionDescriptor = FetchDescriptor<Transaction>()
        do {
            // Get transactions with selected category
            let allTransactions = try fetch(fetchTransactionDescriptor)
            let filtered = allTransactions.filter { $0.category == category }
            // Replace category in transaction with provided replacing category
            filtered.forEach { $0.setCategory(replacingCategory) }
            // Delete initial category
            container.mainContext.delete(category)
            try save()
        } catch {
            print(error)
            return
        }
    }
    
    func deleteCategoryWithTransactions(_ category: Category) async {
        let fetchTransactionDescriptor = FetchDescriptor<Transaction>()
        do {
            // Get transactions with selected category
            let allTransactions = try fetch(fetchTransactionDescriptor)
            let filtered = allTransactions.filter { $0.category == category }
            // Delete transactions
            filtered.forEach { deleteTransaction($0) }
            // Delete category
            container.mainContext.delete(category)
            try save()
        } catch {
            print(error)
            return
        }
    }
    
    func deleteTag(_ tag: Tag) async {
        let fetchTransactionDescriptor = FetchDescriptor<Transaction>()
        do {
            // Get transactions with selected tag
            let allTransactions = try fetch(fetchTransactionDescriptor)
            let filtered = allTransactions.filter { $0.tags.contains(tag) }
            // Remove tag from transactions
            filtered.forEach { $0.removeTag(tag) }
            // Delete tag
            container.mainContext.delete(tag)
            try save()
        } catch {
            print(error)
            return
        }
    }
    
    func deleteTagWithTransactions(_ tag: Tag) async {
        let fetchTransactionDescriptor = FetchDescriptor<Transaction>()
        do {
            // Get transactions with selected tag
            let allTransactions = try fetch(fetchTransactionDescriptor)
            let filtered = allTransactions.filter { $0.tags.contains(tag) }
            // Delete transactions
            filtered.forEach { deleteTransaction($0) }
            // Delete tag
            container.mainContext.delete(tag)
            try save()
        } catch {
            print(error)
            return
        }
    }
    
    func deleteAllTransactions() async {
        do {
            try container.mainContext.delete(model: Transaction.self)
            try save()
        } catch {
            print(error)
            return
        }
    }
    
    func deleteAllStoredData() async {
        do {
            try container.mainContext.delete(model: Transaction.self)
            try container.mainContext.delete(model: BalanceAccount.self)
            UserDefaults.standard.set(nil, forKey: defaultBalanceAccountIdKey)
            try container.mainContext.delete(model: Category.self)
            try container.mainContext.delete(model: Tag.self)
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
        if T.self is BalanceAccount.Type {
            balanceAccounts = fetchedData as? [BalanceAccount] ?? []
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
    
    func setPreferredColorScheme(_ colorScheme: ColorScheme?) {
        preferredColorScheme = colorScheme
        settingsManager.setPreferredColorScheme(colorScheme)
    }
    
    func getPreferredColorScheme() -> ColorScheme? {
        settingsManager.getPreferredColorScheme()
    }
    
    func saveDefaultCategories() {
        for category in defaultSpendingCategories {
            insert(category)
        }
        
        for category in defaultIncomeCategories {
            insert(category)
        }
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
