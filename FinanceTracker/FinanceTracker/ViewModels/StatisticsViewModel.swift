//
//  StatisticsViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 13.06.2024.
//

import Foundation
import SwiftUI
import Algorithms
import SwiftData

enum TransactionFilterTypes: String, Equatable, CaseIterable {
    case both = "Both types"
    case spending = "Spending"
    case income = "Income"
}

enum PieChartDateFilter: String, Equatable, CaseIterable {
    case day = "for a day"
    case month = "For a month"
    case year = "For a year"
    case dateRange = "Specific date range"
    case allTime = "All time"
}

final class StatisticsViewModel: ObservableObject {
    //MARK: - Properties
    let calendar = Calendar.current
    
    //MARK: Private
    /// DataManager to manipulate with ModelContainer of SwiftData
    private let dataManager: any DataManagerProtocol
    
    //MARK: Published
    /// All transactions
    @Published private(set) var transactions: [Transaction] = []
    /// All balance accounts
    @Published private(set) var balanceAccounts: [BalanceAccount] = []
    /// Total value of balance of set account (initial balance + income - spendings)
    @Published private(set) var totalForBalanceAccount: Float = 0
    /// Balance Account to filter all data
    @Published var balanceAccountToFilter: BalanceAccount = .emptyBalanceAccount {
        didSet {
            refreshData()
        }
    }
    
    //Pie chart
    /// Data Array to provide in pie chart
    @Published private(set) var pieChartTransactionData: [(categoryName: String, sumValue: Float)] = []
    /// Filter by type of transactions to display in pie chart
    @Published var pieChartTransactionType: TransactionsType = .spending {
        didSet {
            calculateDataForPieChart()
        }
    }
    /// Which type of date filtering is selected for pie chart
    @Published var pieChartMenuDateFilterSelected: PieChartDateFilter = .allTime {
        didSet {
            calculateDataForPieChart()
        }
    }
    /// For pie chart DatePicker (for a single day, month or year )
    @Published var pieChartDate: Date = .now {
        didSet {
            calculateDataForPieChart()
        }
    }
    /// For pie chart date range, start date
    @Published var pieChartDateStart: Date = .now {
        didSet {
            calculateDataForPieChart()
        }
    }
    /// For pie chart date range, end date
    @Published var pieChartDateEnd: Date = .now {
        didSet {
            calculateDataForPieChart()
        }
    }
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
        refreshData()
    }
    
    //MARK: - Methods
    /// Refreshes all data
    func refreshData() {
        fetchAllData { [weak self] in
            self?.calculateTotalForBalanceAccount()
            self?.calculateDataForPieChart()
        }
    }
    
    //MARK: Private methods
    /// Calculates total value (initial balance + income - spendings) for Balance Account and sets value to totalForBalanceAccount
    /// - Warning: .map uses forse unwraping of transaction type
    private func calculateTotalForBalanceAccount() {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self else { return }
            var totalValue = self.transactions
                .filter { $0.balanceAccount == self.balanceAccountToFilter }
                .map {
                    switch $0.type! {
                    case .spending:
                        return -$0.value
                    case .income:
                        return $0.value
                    }
                }
                .reduce(0, +)
            
            totalValue += balanceAccountToFilter.balance
            
            DispatchQueue.main.async {
                self.totalForBalanceAccount = totalValue
            }
        }
    }
    
    /// Calculates data for pie chart and sets it with animation
    private func calculateDataForPieChart() {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self else { return }
            var returnData = self.transactions
                .filter { $0.type == self.pieChartTransactionType }
                .filter { singleTransaction in
                    switch self.pieChartMenuDateFilterSelected {
                    case .day:
                        return self.calendar.isDate(singleTransaction.date, equalTo: self.pieChartDate, toGranularity: .day)
                    case .month:
                        return self.calendar.isDate(singleTransaction.date, equalTo: self.pieChartDate, toGranularity: .month)
                    case .year:
                        return self.calendar.isDate(singleTransaction.date, equalTo: self.pieChartDate, toGranularity: .year)
                    case .dateRange:
                        let lowerBound = self.calendar.startOfDay(for: self.pieChartDateStart)
                        let higherBound = self.calendar.startOfDay(for: self.calendar.date(byAdding: .day, value: 1, to: self.pieChartDateEnd) ?? self.pieChartDateEnd)
                        return (lowerBound...higherBound).contains(singleTransaction.date)
                    case .allTime:
                        return true
                    }
                }
                .grouped { $0.category }
                .map { singleDict in
                    let categoryName = singleDict.key?.name ?? "Err category"
                    let totalValueForCategory = singleDict.value.map{ $0.value }.reduce(0, +)
                    return (categoryName, totalValueForCategory)
                }
            
            returnData = returnData.sorted(by: { $0.0 < $1.0 })
            
            DispatchQueue.main.async {
                withAnimation {
                    self.pieChartTransactionData = returnData
                }
            }
        }
    }
    
    /// Fetches all data and executes completion handler
    /// - Parameter completionHandler: completion handler that is executed at the end of fetching
    private func fetchAllData(completionHandler: @escaping () -> Void) {
        Task {
            await fetchBalanceAccounts()
            await fetchTransactions()
            completionHandler()
        }
    }
    
    ///Fetches all transactions and sets to transactions
    @MainActor
    private func fetchTransactions() async {
        let descriptor = FetchDescriptor<Transaction>(
            predicate: nil,
            sortBy: [SortDescriptor<Transaction>(\.date, order: .reverse)]
        )
        
        do {
            let fetchedTranses = try dataManager.fetch(descriptor)
            transactions = fetchedTranses
        } catch {
            print("Unable to fetch transactions")
        }
    }
    
    ///Fetches all balance accounts and sets to balanceAccounts
    @MainActor
    private func fetchBalanceAccounts() async {
        let descriptor = FetchDescriptor<BalanceAccount>(
            predicate: nil,
            sortBy: [SortDescriptor<BalanceAccount>(\.name, order: .reverse)]
        )
        
        do {
            let fetchedBalanceAccounts = try dataManager.fetch(descriptor)
            balanceAccounts = fetchedBalanceAccounts
        } catch {
            print("Unable to fetch transactions")
        }
    }
}
