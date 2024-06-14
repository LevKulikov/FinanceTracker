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
    case day = "For a day"
    case month = "For a month"
    case year = "For a year"
    case dateRange = "Date range"
    case allTime = "All time"
}

final class StatisticsViewModel: ObservableObject {
    /// Data types which are calculated for different type of entities
    private enum CalculatingDataType: Equatable {
        case totalValue
        case pieChart
    }
    
    //MARK: - Properties
    let calendar = Calendar.current
    /// Defines if Pie Chart Date range can be moved backward
    var pieDateRangeCanBeMovedBack: Bool {
        return calendar.startOfDay(for: pieChartDateStart) != calendar.startOfDay(for: FTAppAssets.availableDateRange.lowerBound)
    }
    /// Defines if Pie Chart Date range can be moved forward
    var pieDateRangeCanBeMovedForward: Bool {
        return calendar.startOfDay(for: pieChartDateEnd) != calendar.startOfDay(for: FTAppAssets.availableDateRange.upperBound)
    }
    
    //MARK: Private
    /// DataManager to manipulate with ModelContainer of SwiftData
    private let dataManager: any DataManagerProtocol
    /// Flag for allowing data calculation for all data types (enitites)
    private var isCalculationAllowed = true
    
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
    
    //MARK: For pie chart
    /// Data Array to provide in pie chart
    @Published private(set) var pieChartTransactionData: [(category: Category, sumValue: Float)] = []
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
    
    /// Moves date range consiquentely its size to back or forward
    /// - Parameter direction: direction to move date range
    func moveDateRange(direction: DateSettingDestination) {
        guard var numberOfDays = calendar.dateComponents([.day], from: pieChartDateStart, to: pieChartDateEnd).day else {
            print("StatisticsViewModel: moveDateRange(direction:): Unable to get number of dayes between start and end dates")
            return
        }
        
        switch direction {
        case .back:
            guard pieDateRangeCanBeMovedBack else { return }
            numberOfDays = -numberOfDays - 2
        case .forward:
            guard pieDateRangeCanBeMovedForward else { return }
            numberOfDays += 2
        }
        
        guard var newStartDate = calendar.date(byAdding: .day, value: numberOfDays, to: pieChartDateStart),
              var newEndDate = calendar.date(byAdding: .day, value: numberOfDays, to: pieChartDateEnd) else { return }
        
        if !FTAppAssets.availableDateRange.contains(newStartDate) {
            newStartDate = numberOfDays > 0 ? FTAppAssets.availableDateRange.upperBound : FTAppAssets.availableDateRange.lowerBound
        }
        
        if !FTAppAssets.availableDateRange.contains(newEndDate) {
            newEndDate = numberOfDays > 0 ? FTAppAssets.availableDateRange.upperBound : FTAppAssets.availableDateRange.lowerBound
        }
        
        pieChartDateStart = newStartDate
        pieChartDateEnd = newEndDate
    }
    
    /// Sets pie chart date filter to default values
    func setPieChartDateFiltersToDefault() {
        doNotCalculateDataUntilBlockIsFinished({
            pieChartDate = .now
            pieChartDateStart = .now
            pieChartDateEnd = .now
        }, for: .pieChart)
    }
    
    /// For preview only
    func setAnyExistingBA() {
        guard let toset = balanceAccounts.first else { return }
        balanceAccountToFilter = toset
    }
    
    //MARK: Private methods
    /// Prevents recalculation of different data types until provided block of code is executed. This method is needed because of data calculation is caused by didSet observer
    /// - Parameters:
    ///   - block: code to execute before data recalculation
    ///   - calculationData: which data should be calculated after block will be executed. Provide nil if calculation is need for all data types
    private func doNotCalculateDataUntilBlockIsFinished(_ block: () -> Void, for calculationData: CalculatingDataType?) {
        isCalculationAllowed = false
        block()
        isCalculationAllowed = true
        switch calculationData {
        case .totalValue:
            calculateTotalForBalanceAccount()
        case .pieChart:
            calculateDataForPieChart()
        case .none:
            calculateTotalForBalanceAccount()
            calculateDataForPieChart()
        }
    }
    
    /// Calculates total value (initial balance + income - spendings) for Balance Account and sets value to totalForBalanceAccount
    /// - Warning: .map uses forse unwraping of transaction type
    private func calculateTotalForBalanceAccount() {
        guard isCalculationAllowed else { return }
        
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
        guard isCalculationAllowed else { return }
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self else { return }
            var returnData = self.transactions
                .filter { $0.type == self.pieChartTransactionType && $0.balanceAccount == self.balanceAccountToFilter }
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
                    let totalValueForCategory = singleDict.value.map{ $0.value }.reduce(0, +)
                    return (category: singleDict.key ?? .emptyCategory, sumValue: totalValueForCategory)
                }
            
            returnData = returnData.sorted(by: { $0.sumValue > $1.sumValue })
            
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
