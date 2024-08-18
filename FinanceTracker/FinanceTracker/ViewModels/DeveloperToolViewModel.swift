//
//  DeveloperToolViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 18.08.2024.
//

import Foundation
import SwiftData

final class DeveloperToolViewModel: ObservableObject, @unchecked Sendable {
    //MARK: - Properties
    private let dataManager: any DataManagerProtocol
    
    @MainActor @Published private(set) var isProcessing = false
    @MainActor @Published private(set) var balanceAccounts: [BalanceAccount] = []
    @MainActor @Published private(set) var categories: [Category] = []
    @MainActor @Published var selectedBalanceAccount: BalanceAccount?
    @MainActor @Published var selectedCategory: Category?
    @MainActor @Published var transactionsCountString: String = "5000"
    
    //MARK: - Initializer
    init(dataManager: any DataManagerProtocol) {
        self.dataManager = dataManager
        self._selectedBalanceAccount = Published(wrappedValue: dataManager.getDefaultBalanceAccount())
        fetchAllData()
    }
    
    //MARK: - Methods
    func insertTransactions() async {
        await MainActor.run {
            isProcessing = true
        }
        
        let countCopyString = await MainActor.run { return transactionsCountString }
        guard let count = Int(countCopyString) else {
            print("DeveloperToolViewModel, insertTransactions, cannot convert String to Int")
            return
        }
        
        let copyBalanceAcc = await MainActor.run { return selectedBalanceAccount }
        guard let copyBalanceAcc else {
            print("DeveloperToolViewModel, insertTransactions, Balance Account is nil")
            return
        }
        
        let copyCategory = await MainActor.run { return selectedCategory }
        guard let copyCategory else {
            print("DeveloperToolViewModel, insertTransactions, Category is nil")
            return
        }
        
        let countFloat = Float(count)
        for _ in 0..<count {
            let transaction = Transaction(
                type: copyCategory.type ?? TransactionsType(rawValue: copyCategory.typeRawValue) ?? .spending,
                comment: "",
                value: countFloat,
                date: .now,
                balanceAccount: copyBalanceAcc,
                category: copyCategory,
                tags: []
            )
            
            await MainActor.run {
                dataManager.insert(transaction)
            }
        }
        
        await MainActor.run {
            do {
                try dataManager.save()
            } catch {
                print("DeveloperToolViewModel, insertTransactions, Saving error: \(error)")
            }
        }
        
        await MainActor.run {
            isProcessing = false
        }
    }
    
    private func fetchAllData() {
        Task { @MainActor in
            await fetchBalanceAccounts()
            await fetchCategories()
        }
    }
    
    @MainActor
    private func fetchBalanceAccounts() async {
        do {
            let fetchedBAs = try dataManager.fetch(FetchDescriptor<BalanceAccount>())
            balanceAccounts = fetchedBAs
        } catch {
            print("DeveloperToolViewModel, fetchBalanceAccounts, error: \(error)")
        }
    }
    
    @MainActor
    private func fetchCategories() async {
        do {
            let fetchedCategories = try dataManager.fetch(FetchDescriptor<Category>())
            categories = fetchedCategories
        } catch {
            print("DeveloperToolViewModel, fetchCategories, error: \(error)")
        }
    }
}
