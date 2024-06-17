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

enum BarChartPerDateFilter: String, Equatable, CaseIterable {
    case perDay = "Per day"
    case perWeek = "Per week"
    case perMonth = "Per month"
    case perYear = "Per year"
}

final class StatisticsViewModel: ObservableObject {
    /// Data types which are calculated for different type of entities
    private enum CalculatingDataType: Equatable {
        case totalValue
        case pieChart
        case barChart
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
    /// Array of years those are available
    private var availableYearDates: [Date] = []
    /// Array of years with months those are available
    private var availableYearMonthDates: [Date] = []
    /// Array of years with months and week number those are available
    private var availableYearMonthWeekDates: [Date] = []
    /// Array of years with months and days those are available
    private var availableYearMonthDayDates: [Date] = []
    
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
    /// Data Array to be provided in pie chart
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
    
    //MARK: For bar chart
    /// Data Array to be provided to bar chart
    @Published private(set) var barChartTransactionData: [[TransactionBarChartData]] = []
    /// Filter by transactions type (adding both case) to display in bar chart
    @Published var barChartTransactionTypeFilter: TransactionFilterTypes = .spending {
        didSet {
            calculateDataForBarChart()
        }
    }
    /// Filter to select per which type of date to be diplayed in bar chart
    @Published var barChartPerDateFilter: BarChartPerDateFilter = .perWeek {
        didSet {
            calculateDataForBarChart()
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
            self?.calculateDataForBarChart()
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
        case .barChart:
            calculateDataForBarChart()
        case .none:
            calculateTotalForBalanceAccount()
            calculateDataForPieChart()
            calculateDataForBarChart()
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
    
    /// Calculates data for bar chart and sets it with animation
    private func calculateDataForBarChart(on thread: DispatchQueue = .global(qos: .utility)) {
        guard isCalculationAllowed else { return }
        // This is utility because of high calculation compexity
        thread.async { [weak self] in
            guard let self else { return }
            
            let availableBarData = self.transactions
                .filter { singleTransaction in
                    guard singleTransaction.balanceAccount == self.balanceAccountToFilter else {
                        return false
                    }
                    
                    switch self.barChartTransactionTypeFilter {
                    case .both:
                        return true
                    case .spending:
                        return (singleTransaction.type == .spending)
                    case .income:
                        return (singleTransaction.type == .income)
                    }
                }
                .grouped { singleTransaction in
                    let year = self.calendar.component(.year, from: singleTransaction.date)
                    let month = self.calendar.component(.month, from: singleTransaction.date)
                    
                    switch self.barChartPerDateFilter {
                    case .perDay:
                        let day = self.calendar.component(.day, from: singleTransaction.date)
                        return DateComponents(year: year, month: month, day: day)
                    case .perWeek:
                        let dateComp = self.calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: singleTransaction.date)
                        return dateComp
                    case .perMonth:
                        return DateComponents(year: year, month: month)
                    case .perYear:
                        return DateComponents(year: year)
                    }
                }
                .map { singleGroup in
                    let dateToSet = self.calendar.date(from: singleGroup.key) ?? .now
                    let groupedByTransTypeDict = singleGroup.value.grouped { $0.type }
                    
                    var arrayOfBarData =  groupedByTransTypeDict.map {
                        let sumValue = $0.value.map { $0.value }.reduce(0, +)
                        
                        switch $0.key {
                        case .spending:
                            return TransactionBarChartData(type: .spending, value: sumValue, date: dateToSet)
                        case .income:
                            return TransactionBarChartData(type: .income, value: sumValue, date: dateToSet)
                        case .none:
                            return TransactionBarChartData(type: .unknown, value: sumValue, date: dateToSet)
                        }
                    }
                    
                    if case .both = self.barChartTransactionTypeFilter {
                        var incomeTransData = arrayOfBarData.first { $0.type == .income }
                        if incomeTransData == nil {
                            incomeTransData = TransactionBarChartData(type: .income, value: 0, date: dateToSet)
                            arrayOfBarData.append(incomeTransData!)
                        }
                        
                        var spendTransData = arrayOfBarData.first { $0.type == .spending }
                        if spendTransData == nil {
                            spendTransData = TransactionBarChartData(type: .spending, value: 0, date: dateToSet)
                            arrayOfBarData.append(spendTransData!)
                        }
                        
                        let profitValue = incomeTransData!.value - spendTransData!.value
                        let profitData = TransactionBarChartData(type: .profit, value: profitValue, date: dateToSet)
                        arrayOfBarData.append(profitData)
                    }
                    
                    return arrayOfBarData
                }
            
            // Useless code because Bar Charts algorithms
            //let filledBarData = addEmptyDataTo(availableBarData)
            
            DispatchQueue.main.async {
                withAnimation {
                    self.barChartTransactionData = availableBarData
                }
            }
        }
    }
    
    /// Fills date gaps with empty TransactionBarChartData
    /// - Parameter barChartData: existing TransactionBarChartData
    /// - Returns: filled and sorted array of arrays of bar chart data
    private func addEmptyDataTo(_ barChartData: [[TransactionBarChartData]]) -> [[TransactionBarChartData]] {
        var usedDateArray: [Date]
        var dateComponentsToUse: Set<Calendar.Component> = []
        switch barChartPerDateFilter {
        case .perDay:
            usedDateArray = availableYearMonthDayDates
            dateComponentsToUse.insert(.day)
            dateComponentsToUse.insert(.month)
            dateComponentsToUse.insert(.year)
        case .perWeek:
            usedDateArray = availableYearMonthWeekDates
            dateComponentsToUse.insert(.calendar)
            dateComponentsToUse.insert(.yearForWeekOfYear)
            dateComponentsToUse.insert(.weekOfYear)
        case .perMonth:
            usedDateArray = availableYearMonthDates
            dateComponentsToUse.insert(.month)
            dateComponentsToUse.insert(.year)
        case .perYear:
            usedDateArray = availableYearDates
            dateComponentsToUse.insert(.year)
        }
        
        let returnArray = usedDateArray
            .map { date in
                let filterDateComponent = calendar.dateComponents(dateComponentsToUse, from: date)
                if let equelTransaction = barChartData.first(where: { transDataArray in
                    guard let firstTrans = transDataArray.first else { return false }
                    let transDateComponents = calendar.dateComponents(dateComponentsToUse, from: firstTrans.date)
                    return (filterDateComponent == transDateComponents)
                }) {
                    return equelTransaction
                }
                
                var returnTransData: [TransactionBarChartData] = []
                let emptySpendingTransData = TransactionBarChartData(type: .spending, value: 0, date: date)
                let emptyIncomeTransData = TransactionBarChartData(type: .income, value: 0, date: date)
                let emptyProfitTransData = TransactionBarChartData(type: .profit, value: 0, date: date)
                
                switch barChartTransactionTypeFilter {
                case .both:
                    returnTransData.append(emptySpendingTransData)
                    returnTransData.append(emptyIncomeTransData)
                    returnTransData.append(emptyProfitTransData)
                case .spending:
                    returnTransData.append(emptySpendingTransData)
                case .income:
                    returnTransData.append(emptyIncomeTransData)
                }
                
                return returnTransData
            }
        
        return returnArray
    }
    
    /// Sets available dates arrays for only years and years with months (useless)
    private func setDateArrays(completionHandler: @escaping () -> Void) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            
            let availabelDateRange = FTAppAssets.availableDateRange
            var yearDateArray: [Date?] = []
            var yearMonthDateArray: [Date?] = []
            var yearMonthDayDateArray: [Date?] = []
            var yearMonthWeekDateArray: [Date?] = []
            let standardMonthArray = Array(1...12)
            let standardDayArray = Array(1...31)
            let maxYear = calendar.component(.year, from: availabelDateRange.upperBound)
            let maxMonth = calendar.component(.month, from: availabelDateRange.upperBound)
            let maxDay = calendar.component(.day, from: availabelDateRange.upperBound)
            
            let yearRange = calendar.component(.year, from: availabelDateRange.lowerBound)...calendar.component(.year, from: availabelDateRange.upperBound)
            yearLoop: for oneYear in yearRange {
                let yearDate = calendar.date(from: DateComponents(year: oneYear))
                yearDateArray.append(yearDate)
                
                monthLoop: for monthNumber in standardMonthArray {
                    let monthDateComponent = DateComponents(year: oneYear, month: monthNumber)
                    let monthDate = calendar.date(from: monthDateComponent)
                    yearMonthDateArray.append(monthDate)
                    
                    dayLoop: for dayNumber in standardDayArray {
                        let dayDateComponent = DateComponents(year: oneYear, month: monthNumber, day: dayNumber)
                        let dayDate = calendar.date(from: dayDateComponent)
                        
                        let startOfWeekDate = dayDate?.startOfWeek()
                        if !yearMonthWeekDateArray.contains(startOfWeekDate) {
                            yearMonthWeekDateArray.append(startOfWeekDate)
                        }
                        
                        if oneYear == maxYear, monthNumber == maxMonth, dayNumber == (maxDay + 1) {
                            yearMonthDayDateArray.append(dayDate)
                            break yearLoop
                        }
                        yearMonthDayDateArray.append(dayDate)
                    }
                }
            }
            self.availableYearDates = yearDateArray.compactMap { $0 }
            self.availableYearMonthDates = yearMonthDateArray.compactMap { $0 }
            self.availableYearMonthDayDates = yearMonthDayDateArray.compactMap { $0 }
            self.availableYearMonthWeekDates = yearMonthWeekDateArray.compactMap { $0 }
            completionHandler()
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
