//
//  BudgetCardViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 18.07.2024.
//

import Foundation
import SwiftData
import SwiftUI

final class BudgetCardViewModel: ObservableObject {
    //MARK: - Properties
    let budget: Budget
    
    //MARK: Published properties
    @Published private(set) var isProcessing = false
    @Published private(set) var totalValue: Float = 0
    
    //MARK: Private properties
    private let dataManager: any DataManagerProtocol
    private var transactions: [Transaction] = []
    private let caledar: Calendar = .current
    
    //MARK: - Initializer
    init(dataManager: any DataManagerProtocol, budget: Budget) {
        self.dataManager = dataManager
        self.budget = budget
        fetchAndCalculate()
    }
    
    //MARK: - Methods
    
    //MARK: Private methods
    func fetchAndCalculate(compeletionHandler: (() -> Void)? = nil) {
        isProcessing = true
        Task {
            await fetchTransactions()
            await calculateTotalValue()
            compeletionHandler?()
            DispatchQueue.main.async { [weak self] in
                self?.isProcessing = false
            }
        }
    }
    
    private func calculateTotalValue() async {
        let value = transactions.map { $0.value }.reduce(0, +)
        
        Task.detached { @MainActor in
            withAnimation {
                self.totalValue = value
            }
        }
    }
    
    private func fetchTransactions(errorHandler: ((Error) -> Void)? = nil) async {
        var startDate: Date
        var endDate: Date
        
        switch budget.period {
        case .week:
            startDate = .now.startOfWeek() ?? .now
            endDate = .now.endOfWeek() ?? .now
        case .month:
            startDate = .now.startOfMonth() ?? .now
            endDate = .now.endOfMonth() ?? .now
        case .year:
            startDate = .now.startOfYear() ?? .now
            endDate = .now.endOfYear() ?? .now
        }
        
        let forSpecificCategory = budget.category != nil ? true : false
        let categoryId = budget.category?.id
        let balanceAccountId = budget.balanceAccount?.id
        
        let predicate = #Predicate<Transaction> { transaction in
            if (startDate...endDate).contains(transaction.date) {
                if forSpecificCategory {
                    if transaction.category?.id == categoryId {
                        return transaction.balanceAccount?.id == balanceAccountId
                    } else {
                        return false
                    }
                } else {
                    return transaction.balanceAccount?.id == balanceAccountId
                }
            } else {
                return false
            }
        }
        
        let descriptor = FetchDescriptor<Transaction>(predicate: predicate)
        
        do {
            let fetchedTransactions = try await dataManager.fetchFromBackground(descriptor)
            transactions = fetchedTransactions
        } catch {
            errorHandler?(error)
            return
        }
    }
}
