//
//  DataManager.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 25.05.2024.
//

import Foundation
@preconcurrency import SwiftData
import SwiftUI

protocol DataManagerProtocol: AnyObject {
    var tagDefaultColor: Color? { get set }
    var isFirstLaunch: Bool { get set }
    
    @MainActor
    func save() throws
    
    func saveFromBackground() async throws
    
    @MainActor
    func deleteTransaction(_ transaction: Transaction)
    
    func deleteTransactionFromBackground(_ transaction: Transaction) async throws
    
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
    func deleteBudget(_ budget: Budget) async
    
    @MainActor
    func deleteAllTransactions() async
    
    @MainActor
    func deleteAllStoredData() async
    
    @MainActor
    func insert<T>(_ model: T) where T : PersistentModel
    
    func insertFromBackground<T>(_ model: T) async where T : PersistentModel
    
    @MainActor
    func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] where T : PersistentModel
    
    func fetchFromBackground<T>(_ descriptor: FetchDescriptor<T>) async throws -> [T] where T : PersistentModel
    
    func setDefaultBalanceAccount(_ balanceAccount: BalanceAccount)
    
    func getDefaultBalanceAccount() -> BalanceAccount?
    
    func setPreferredColorScheme(_ colorScheme: ColorScheme?)
    
    func getPreferredColorScheme() -> ColorScheme?
    
    @MainActor
    func saveDefaultCategories()
}

final class DataManager: DataManagerProtocol, @unchecked Sendable, ObservableObject {
    enum DataThread: Equatable {
        case main
        case global
    }
    
    //MARK: - Properties
    private let container: ModelContainer
    private var backgroundActor: BackgroundDataActor?
    private let settingsManager: any SettingsManagerProtocol
    private let defaultBalanceAccountIdKey = "defaultBalanceAccountIdKey"
    private var balanceAccounts: [BalanceAccount] = []
    private let defaultSpendingCategories: [Category] = [
        .init(type: .spending, name: String(localized: "Groceries"), iconName: "shopping-cart", color: .blue, placement: 1),
        .init(type: .spending, name: String(localized: "Сafes"), iconName: "003-cutlery", color: .yellow, placement: 2),
        .init(type: .spending, name: String(localized: "Transport"), iconName: "car", color: .orange, placement: 3),
        .init(type: .spending, name: String(localized: "Entertainments"), iconName: "001-gamepad", color: .indigo, placement: 4),
        .init(type: .spending, name: String(localized: "Education"), iconName: "016-book", color: .purple, placement: 5),
        .init(type: .spending, name: String(localized: "Health"), iconName: "018-heart", color: .red, placement: 6),
        .init(type: .spending, name: String(localized: "Gifts"), iconName: "031-gift", color: .mint, placement: 7),
        .init(type: .spending, name: String(localized: "Home"), iconName: "home", color: .brown, placement: 8),
        .init(type: .spending, name: String(localized: "Family"), iconName: "010-love-3", color: .pink, placement: 9),
        .init(type: .spending, name: String(localized: "Other"), iconName: "047-upload", color: .red, placement: 10),
    ]
    private let defaultIncomeCategories: [Category] = [
        .init(type: .income, name: String(localized: "Gifts"), iconName: "031-gift", color: .mint, placement: 3),
        .init(type: .income, name: String(localized: "Salary"), iconName: "1-economy-004-economy", color: .green, placement: 1),
        .init(type: .income, name: String(localized: "Interest"), iconName: "1-economy-007-bank", color: .purple, placement: 2),
        .init(type: .income, name: String(localized: "Other"), iconName: "download", color: .green, placement: 4),
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
    
    func saveFromBackground() async throws {
        if let backgroundActor {
            try await backgroundActor.save()
        } else {
            backgroundActor = BackgroundDataActor(modelContainer: container)
            try await backgroundActor!.save()
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        container.mainContext.delete(transaction)
        // Because of iOS 18 Beta bug of SwiftData, it is needed to delete transaction from both main and background contexts
        if #available(iOS 18.0, *) {
            Task {
                do {
                    try await deleteTransactionById(transaction)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func deleteTransactionFromBackground(_ transaction: Transaction) async throws {
        if let backgroundActor {
            await backgroundActor.delete(transaction)
            try await backgroundActor.save()
        } else {
            backgroundActor = BackgroundDataActor(modelContainer: container)
            await backgroundActor!.delete(transaction)
            try await backgroundActor!.save()
        }
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
    
    func deleteBudget(_ budget: Budget) async {
        do {
            container.mainContext.delete(budget)
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
        do {
            container.mainContext.insert(model)
            try save()
        } catch {
            print(error)
            return
        }
    }
    
    func insertFromBackground<T>(_ model: T) async where T : PersistentModel, T: Sendable {
        do {
            if let backgroundActor {
                await backgroundActor.insert(model)
                try await backgroundActor.save()
            } else {
                backgroundActor = BackgroundDataActor(modelContainer: container)
                await backgroundActor!.insert(model)
                try await backgroundActor!.save()
            }
        } catch {
            print(error)
            return
        }
    }
    
    func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] where T : PersistentModel {
        let fetchedData = try container.mainContext.fetch(descriptor)
        if T.self is BalanceAccount.Type {
            balanceAccounts = fetchedData as? [BalanceAccount] ?? []
        }
        return fetchedData
    }
    
    /// Should be firstly used from background thread. Otherwise it will be execute from main thread
    func fetchFromBackground<T>(_ descriptor: FetchDescriptor<T>) async throws -> [T] where T : PersistentModel, T: Sendable {
        if let backgroundActor {
            return try await backgroundActor.fetch(descriptor)
        } else {
            backgroundActor = BackgroundDataActor(modelContainer: container)
            return try await backgroundActor!.fetch(descriptor)
        }
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
    
    private func deleteTransactionById(_ transaction: Transaction) async throws {
        if let backgroundActor {
            try await backgroundActor.deleteTransactionById(transaction)
            try await backgroundActor.save()
        } else {
            backgroundActor = BackgroundDataActor(modelContainer: container)
            try await backgroundActor!.deleteTransactionById(transaction)
            try await backgroundActor!.save()
        }
    }
}
