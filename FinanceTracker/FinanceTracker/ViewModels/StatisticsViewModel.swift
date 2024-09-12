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

protocol StatisticsViewModelDelegate: AnyObject {
    func showTabBar(_ show: Bool)
    
    func didUpdatedTransactionsListFromStatistics()
}

enum TransactionFilterTypes: LocalizedStringResource, Equatable, CaseIterable, Identifiable {
    case both = "Both types"
    case spending = "Spending"
    case income = "Income"
    
    var id: Self {
        return self
    }
    
    var binaryTransactionType: TransactionsType? {
        switch self {
        case .both:
            return nil
        case .spending:
            return .spending
        case .income:
            return .income
        }
    }
}

enum PieChartDateFilter: LocalizedStringResource, Equatable, CaseIterable, Identifiable {
    case day = "For a day"
    case month = "For a month"
    case year = "For a year"
    case dateRange = "Date range"
    case allTime = "All time"
    
    var id: Self {
        return self
    }
}

enum BarChartPerDateFilter: LocalizedStringResource, Equatable, CaseIterable, Identifiable {
    case perDay = "Per day"
    case perWeek = "Per week"
    case perMonth = "Per month"
    case perYear = "Per year"
    
    var id: Self {
        return self
    }
}

final class StatisticsViewModel: ObservableObject, @unchecked Sendable {
    /// Data types which are calculated for different type of entities
    private enum CalculatingDataType: Equatable {
        case totalValue
        case tagsValue
        case pieChart
        case barChart
    }
    
    enum NavigationDestination: Hashable {
        case tagsView
    }
    
    //MARK: - Properties
    /// Delegate for StatisticsViewModel
    weak var delegate: (any StatisticsViewModelDelegate)?
    /// Current calendar
    let calendar = Calendar.current
    /// Defines if Pie Chart Date range can be moved backward
    var pieDateRangeCanBeMovedBack: Bool {
        return calendar.startOfDay(for: pieChartDateStart) != calendar.startOfDay(for: FTAppAssets.availableDateRange.lowerBound)
    }
    /// Defines if Pie Chart Date range can be moved forward
    var pieDateRangeCanBeMovedForward: Bool {
        return calendar.startOfDay(for: pieChartDateEnd) != calendar.startOfDay(for: FTAppAssets.availableDateRange.upperBound)
    }
    /// Date range for selected date (period) type for light weight statistics
    var lightWeightDateFilterRange: ClosedRange<Date> {
        switch lightWeightDateType {
        case .day:
            let startDate = lightWeightDate.startOfDay()
            let endDate = lightWeightDate.endOfDay() ?? lightWeightDate
            return startDate...endDate
        case .week:
            let startDate = lightWeightDate.startOfWeek() ?? lightWeightDate
            let endDate = lightWeightDate.endOfWeek() ?? lightWeightDate
            return startDate...endDate
        case .month:
            let startDate = lightWeightDate.startOfMonth() ?? lightWeightDate
            let endDate = lightWeightDate.endOfMonth() ?? lightWeightDate
            return startDate...endDate
        case .year:
            let startDate = lightWeightDate.startOfYear() ?? lightWeightDate
            let endDate = lightWeightDate.endOfYear() ?? lightWeightDate
            return startDate...endDate
        case .customDateRange:
            let startDate = lightWeightDateStart.startOfDay()
            let endDate = lightWeightDateEnd.endOfDay() ?? lightWeightDate
            return startDate...endDate
        }
    }
    /// Flag that indicates if statistics view is currently displayed
    @MainActor var isViewDisplayed = false
    
    //MARK: Private
    /// DataManager to manipulate with ModelContainer of SwiftData
    private let dataManager: any DataManagerProtocol
    /// Flag for allowing data calculation for all data types (enitites)
    private var isCalculationAllowed = true
    /// Flag to determine if any transaction was updated from another view. Prevents multiple recalculations if several transactions were updated
    private var isTransactionUpdatedFromAnotherView = false
    /// Array of years those are available
    private var availableYearDates: [Date] = []
    /// Array of years with months those are available
    private var availableYearMonthDates: [Date] = []
    /// Array of years with months and week number those are available
    private var availableYearMonthWeekDates: [Date] = []
    /// Array of years with months and days those are available
    private var availableYearMonthDayDates: [Date] = []
    /// All transactions
    private var transactions: [Transaction] = []
    /// All tags
    private(set) var allTags: [Tag] = []
    
    //MARK: Published
    /// All balance accounts
    @Published private(set) var balanceAccounts: [BalanceAccount] = []
    /// Total value of balance of set account (initial balance + income - spendings)
    @Published private(set) var totalForBalanceAccount: Float = 0
    /// Flag to identify total for balance account value is currently being calculate
    @Published private(set) var totalIsCalculating = false
    /// Balance Account to filter all data
    @Published var balanceAccountToFilter: BalanceAccount = .emptyBalanceAccount {
        didSet {
            guard balanceAccountToFilter.id != oldValue.id else { return }
            refreshData()
        }
    }
    /// Flag to determine if data is currently fetching, works in fetchAllData method
    @Published private(set) var isFetchingData = false
    /// Flag to determine if statistics is complete or light weighted
    @Published var lightWeightStatistics = false {
        didSet {
            dataManager.setLightWeightStatistics(lightWeightStatistics)
            refreshData()
        }
    }
    /// For which period of time light weight statistics are displayed
    @Published var lightWeightDateType: DateFilterType = .month {
        didSet {
            refreshData()
        }
    }
    /// For which date light weight statistics are displayed
    @Published var lightWeightDate: Date = .now {
        didSet {
            refreshData()
        }
    }
    /// For custom date range of light weight statistics
    @Published var lightWeightDateStart: Date = .now
    /// For custom date range of light weight statistics
    @Published var lightWeightDateEnd: Date = .now
    /// Total value of spending for a selected balance account. Used for light weight statistics
    @Published private(set) var balanceAccountTotalSpending: Float = 0
    /// Total value of spending for a selected balance account. Used for light weight statistics
    @Published private(set) var balanceAccountTotalIncome: Float = 0
    
    //MARK: For tags statistics
    /// Data array to be provided in tags statistics
    @Published private(set) var tagsTotalData: [TagChartData] = []
    /// Transaction type to select of which transactins should be shown as total for tags data
    @Published var transactionTypeForTags: TransactionsType = .spending {
        didSet {
            guard transactionTypeForTags != oldValue else { return }
            calculateTagsTotal(animated: true)
        }
    }
    /// Flag to identify if tags statistics data is currently being calculate
    @Published private(set) var tagsDataIsCalculating: Bool = false
    
    //MARK: For pie chart
    /// Data Array to be provided in pie chart
    @Published private(set) var pieChartTransactionData: [TransactionPieChartData] = []
    /// Filter by type of transactions to display in pie chart
    @Published var pieChartTransactionType: TransactionsType = .spending {
        didSet {
            guard pieChartTransactionType != oldValue else { return }
            calculateDataForPieChart(animated: true)
        }
    }
    /// Which type of date filtering is selected for pie chart
    @Published var pieChartMenuDateFilterSelected: PieChartDateFilter = .month {
        didSet {
            guard pieChartMenuDateFilterSelected != oldValue else { return }
            calculateDataForPieChart(animated: true)
        }
    }
    /// For pie chart DatePicker (for a single day, month or year )
    @Published var pieChartDate: Date = .now {
        didSet {
            guard pieChartDate != oldValue else { return }
            calculateDataForPieChart(animated: true)
        }
    }
    /// For pie chart date range, start date
    @Published var pieChartDateStart: Date = .now {
        didSet {
            guard pieChartDateStart != oldValue else { return }
            calculateDataForPieChart(animated: true)
        }
    }
    /// For pie chart date range, end date
    @Published var pieChartDateEnd: Date = .now {
        didSet {
            guard pieChartDateEnd != oldValue else { return }
            calculateDataForPieChart(animated: true)
        }
    }
    /// Flag to identify if pie chart data is currently being calculate
    @Published private(set) var pieDataIsCalculating: Bool = false
    
    //MARK: For bar chart
    /// Data Array to be provided to bar chart
    @Published private(set) var barChartTransactionData: [[TransactionBarChartData]] = []
    /// Filter by transactions type (adding both case) to display in bar chart
    @Published var barChartTransactionTypeFilter: TransactionFilterTypes = .spending {
        didSet {
            guard barChartTransactionTypeFilter != oldValue else { return }
            calculateDataForBarChart(animated: true)
        }
    }
    /// Filter to select per which type of date to be diplayed in bar chart
    @Published var barChartPerDateFilter: BarChartPerDateFilter = .perDay {
        didSet {
            guard barChartPerDateFilter != oldValue else { return }
            calculateDataForBarChart(animated: true)
        }
    }
    /// Flag to identify if bar chart data is currently being calculate
    @Published private(set) var barDataIsCalculating: Bool = false
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
        self._lightWeightStatistics = Published(wrappedValue: dataManager.isLightWeightStatistics())
        DispatchQueue.main.async { [weak self] in
            self?.balanceAccountToFilter = self?.dataManager.getDefaultBalanceAccount() ?? .emptyBalanceAccount
        }
    }
    
    //MARK: - Methods
    /// Refreshes all data
    func refreshData(compeletionHandler: (@MainActor @Sendable () -> Void)? = nil) {
        guard !isFetchingData else {
            print("refreshData, data is already being refetched")
            return
        }
        print("refreshData, started")
        fetchAllData { [weak self] in
            if let self, self.lightWeightStatistics {
                self.calculateSpendIncomeValues()
            } else {
                self?.calculateTotalForBalanceAccount()
            }
            self?.calculateTagsTotal(animated: true)
            self?.calculateDataForPieChart(animated: true)
            self?.calculateDataForBarChart()
            print("refreshData, ended")
            Task { @MainActor in
                compeletionHandler?()
            }
        }
    }
    
    /// Refreshes data if some changes occured, otherwise do nothing
    /// - Parameter compeletionHandler: closure that is called at the end of refreshing
    func refreshDataIfNeeded(compeletionHandler: (@MainActor @Sendable () -> Void)? = nil) {
        guard isTransactionUpdatedFromAnotherView else { return }
        isTransactionUpdatedFromAnotherView = false
        refreshData(compeletionHandler: compeletionHandler)
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
        
        doNotCalculateDataUntilBlockIsFinished(for: .pieChart) {
            pieChartDateStart = newStartDate
            pieChartDateEnd = newEndDate
        }
    }
    
    /// Sets pie chart date filter to default values
    func setPieChartDateFiltersToDefault() {
        doNotCalculateDataUntilBlockIsFinished(for: .pieChart) {
            pieChartDate = .now
            pieChartDateStart = .now
            pieChartDateEnd = .now
        }
    }
    
    /// Provides View for Tags settings
    /// - Returns: View for tags settings
    @MainActor
    func getTagsView() -> some View {
        return FTFactory.shared.createTagsView(dataManager: dataManager, delegate: self)
    }
    
    /// Provides View for list of transactions
    /// - Parameters:
    ///   - transactions: transactions to be displayed in list
    ///   - title: title to be set in the returned view
    /// - Returns: TransactionListView with view model
    @MainActor
    func getTransactionListView(transactions: [Transaction], title: String) -> some View {
        return FTFactory.shared.createTransactionListView(dataManager: dataManager, transactions: transactions, title: title, threadToUse: .global, delegate: self)
    }
    
    //MARK: Private methods
    /// Prevents recalculation of different data types until provided block of code is executed. This method is needed because of data calculation is caused by didSet observer
    /// - Parameters:
    ///   - block: code to execute before data recalculation
    ///   - calculationData: which data should be calculated after block will be executed. Provide nil if calculation is need for all data types
    private func doNotCalculateDataUntilBlockIsFinished(for calculationData: CalculatingDataType?, _ block: () -> Void) {
        isCalculationAllowed = false
        block()
        isCalculationAllowed = true
        switch calculationData {
        case .totalValue:
            if lightWeightStatistics {
                calculateSpendIncomeValues()
            } else {
                calculateTotalForBalanceAccount()
            }
        case .tagsValue:
            calculateTagsTotal()
        case .pieChart:
            calculateDataForPieChart()
        case .barChart:
            calculateDataForBarChart()
        case .none:
            if lightWeightStatistics {
                calculateSpendIncomeValues()
            } else {
                calculateTotalForBalanceAccount()
            }
            calculateTagsTotal()
            calculateDataForPieChart()
            calculateDataForBarChart()
        }
    }
    
    /// Calculates total value (initial balance + income - spendings) for Balance Account and sets value to totalForBalanceAccount
    private func calculateTotalForBalanceAccount() {
        guard isCalculationAllowed else { return }
        print("calculateTotalForBalanceAccount, started")
        DispatchQueue.main.async { [weak self] in
            self?.totalIsCalculating = true
        }
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            print("calculateTotalForBalanceAccount, started to calculate totalValue")
            let totalValue = self.transactions
                .map {
                    guard let transType = $0.type else { return Float(0)}
                    switch transType {
                    case .spending:
                        return -$0.value
                    case .income:
                        return $0.value
                    }
                }
                .reduce(balanceAccountToFilter.balance, +)
            
            DispatchQueue.main.async {
                print("calculateTotalForBalanceAccount, provided data")
                self.totalIsCalculating = false
                self.totalForBalanceAccount = totalValue
                print("calculateTotalForBalanceAccount, ended")
            }
        }
    }
    
    /// Calculates total spendings and total incomes values for a selected balance account. Used for light weight statistics
    private func calculateSpendIncomeValues() {
        guard isCalculationAllowed else { return }
        
        Task.detached(priority: .high) { [transactions] in
            var totalSpendings: Float = 0
            var totalIncome: Float = 0
            for transaction in transactions {
                switch transaction.type {
                case .spending:
                    totalSpendings += transaction.value
                case .income:
                    totalIncome += transaction.value
                case .none:
                    continue
                }
            }
            
            await MainActor.run { [totalSpendings, totalIncome] in
                self.balanceAccountTotalSpending = totalSpendings
                self.balanceAccountTotalIncome = totalIncome
            }
        }
    }
    
    /// Calculate total value for all time tags spending or income
    private func calculateTagsTotal(animated: Bool = false) {
        guard isCalculationAllowed else { return }
        print("calculateTagsTotal, started to calculate data for tags chart")
        DispatchQueue.main.async { [weak self] in
            self?.tagsDataIsCalculating = true
        }
        
        DispatchQueue.global().async { [weak self] in
            guard let self else { return }
            print("calculateTagsTotal, started to calculate data for transactionsWithTags")
            let transactionsWithTags = self.transactions
                .filter { !$0.tags.isEmpty && $0.type == self.transactionTypeForTags  }
            
            guard !transactionsWithTags.isEmpty else {
                print("calculateTagsTotal, started to providing data due guard statement")
                DispatchQueue.main.async {
                    self.tagsDataIsCalculating = false
                    if animated {
                        withAnimation {
                            self.tagsTotalData = []
                        }
                    } else {
                        self.tagsTotalData = []
                    }
                    print("calculateTagsTotal, ended due guard statement")
                }
                return
            }
            
            print("calculateTagsTotal, started to calcuate tagsData")
            let tagsData = transactionsWithTags
                .flatMap { transaction in
                    var tupleArray: [(tag: Tag, transaction: Transaction)] = []
                    for tag in transaction.tags {
                        tupleArray.append((tag: tag, transaction: transaction))
                    }
                    return tupleArray
                }
                .grouped { $0.tag }
                .map { tagDict in
                    var total: Float = 0
                    var transactionsToSet: [Transaction] = []
                    for tuple in tagDict.value {
                        total += tuple.transaction.value
                        transactionsToSet.append(tuple.transaction)
                    }
                    return TagChartData(tag: tagDict.key, total: total, transactions: transactionsToSet)
                }
                .sorted { $0.total > $1.total}
            
            print("calculateTagsTotal, started to providing data to tags chart")
            DispatchQueue.main.async {
                self.tagsDataIsCalculating = false
                withAnimation {
                    self.tagsTotalData = tagsData
                }
                print("calculateTagsTotal, ended")
            }
        }
    }
    
    /// Calculates data for pie chart and sets it with animation
    private func calculateDataForPieChart(animated: Bool = false) {
        guard isCalculationAllowed else { return }
        print("calculateDataForPieChart, started to calculate data for pie chart")
        DispatchQueue.main.async { [weak self] in
            self?.pieDataIsCalculating = true
        }
        
        DispatchQueue.global(qos: .utility).async { [weak self, lightWeightStatistics, transactions] in
            guard let self else { return }
            print("calculateDataForPieChart, started to calculate returnData")
            let dateAndTypeFilteredData = transactions
                    .filter { singleTransaction in
                        guard !lightWeightStatistics else {
                            return singleTransaction.type == self.pieChartTransactionType
                        }
                        guard singleTransaction.type == self.pieChartTransactionType else { return false }
                        
                        
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
            
            var returnData = dateAndTypeFilteredData
                .grouped { $0.category }
                .map { singleDict in
                    let totalValueForCategory = singleDict.value.map{ $0.value }.reduce(0, +)
                    let transactions = singleDict.value
                    return TransactionPieChartData(category: singleDict.key ?? .emptyCategory, sumValue: totalValueForCategory, transactions: transactions)
                }
            
            print("calculateDataForPieChart, started to sort returnData")
            returnData = returnData.sorted(by: { $0.sumValue > $1.sumValue })
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [returnData] in
                print("calculateDataForPieChart, started to provide data for pie chart")
                self.pieDataIsCalculating = false
                if animated {
                    withAnimation {
                        self.pieChartTransactionData = returnData
                    }
                } else {
                    self.pieChartTransactionData = returnData
                }
                print("calculateDataForPieChart, ended")
            }
        }
    }
    
    /// Calculates data for bar chart and sets it with animation
    private func calculateDataForBarChart(on thread: DispatchQueue = .global(qos: .utility), animated: Bool = false) {
        guard isCalculationAllowed else { return }
        print("calculateDataForBarChart, started to calculate data for bar chart")
        DispatchQueue.main.async { [weak self] in
            self?.barDataIsCalculating = true
        }
        
        // This is utility because of high calculation compexity
        thread.async { [weak self] in
            guard let self else { return }
            print("calculateDataForBarChart, started to calculate availableBarData")
            let availableBarData = self.transactions
                .filter { singleTransaction in
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
                    
                    if self.barChartTransactionTypeFilter == .both {
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
            
            DispatchQueue.main.async {
                print("calculateDataForBarChart, providing data for bar chart")
                self.barDataIsCalculating = false
                if animated {
                    withAnimation {
                        self.barChartTransactionData = availableBarData
                    }
                } else {
                    self.barChartTransactionData = availableBarData
                }
                print("calculateDataForBarChart, ended")
            }
        }
    }
    
    /// Cleans properties with data for UI by setting empty values
    @MainActor
    private func cleanData() {
        balanceAccounts = []
        totalForBalanceAccount = 0
        tagsTotalData = []
        pieChartTransactionData = []
        barChartTransactionData = []
    }
    
    /// Fetches all data and executes completion handler
    /// - Parameter completionHandler: completion handler that is executed at the end of fetching
    private func fetchAllData(completionHandler: @Sendable @escaping () -> Void) {
        isFetchingData = true
        print("fetchAllData, started")
        let localCompletion: @Sendable () -> Void = {
            print("fetchAllData, started to provide data on main thread")
            Task { @MainActor in
                self.isFetchingData = false
            }
            print("fetchAllData, ended")
            completionHandler()
            print("fetchAllData, ended competion handler")
        }
        
        Task {
            print("fetchAllData, started to fetch BAs")
            await fetchBalanceAccounts()
            print("fetchAllData, ended to fetch BAs")
            Task.detached(priority: .background) { [weak self] in
                print("fetchAllData, started to fetch tags")
                await self?.fetchTags()
                print("fetchAllData, ended to fetch tags")
                print("fetchAllData, started to fetch transactions")
                if let self, self.lightWeightStatistics {
                    await self.fetchTransactionszForDate()
                } else {
                    await self?.fetchTransactions()
                }
                print("fetchAllData, ended to fetch transactions")
                localCompletion()
            }
        }
    }
    
    ///Fetches all transactions and sets to transactions, uses background fetching
    private func fetchTransactions() async {
        let copyBalanceAccountId = balanceAccountToFilter.persistentModelID
        let predicate = #Predicate<Transaction> { trans in
            trans.balanceAccount?.persistentModelID == copyBalanceAccountId
        }
        
        var descriptor = FetchDescriptor<Transaction>(
            predicate: predicate,
            sortBy: [SortDescriptor<Transaction>(\.date, order: .reverse)]
        )
        descriptor.relationshipKeyPathsForPrefetching = [\.category, \.balanceAccount]
        
        do {
            let fetchedTranses = try await dataManager.fetchFromBackground(descriptor)
            transactions = fetchedTranses
        } catch {
            print("StatisticsViewModel: Unable to fetch transactions, error: \(error)")
        }
    }
    
    ///Fetches transactions with date filter and sets to transactions, uses background fetching. Used for light weigh statistics
    private func fetchTransactionszForDate() async {
        let copyBalanceAccountId = balanceAccountToFilter.persistentModelID
        let lowerBound = lightWeightDateFilterRange.lowerBound
        let upperBound = lightWeightDateFilterRange.upperBound
        
        let predicate = #Predicate<Transaction> {
            $0.balanceAccount?.persistentModelID == copyBalanceAccountId && (lowerBound...upperBound).contains($0.date)
        }
        
        var descriptor = FetchDescriptor<Transaction>(
            predicate: predicate,
            sortBy: [SortDescriptor<Transaction>(\.date, order: .reverse)]
        )
        descriptor.relationshipKeyPathsForPrefetching = [\.category, \.balanceAccount]
        
        do {
            let fetchedTranses = try await dataManager.fetchFromBackground(descriptor)
            transactions = fetchedTranses
        } catch {
            print("StatisticsViewModel, fetchTransactionsForDate() : Unable to fetch transactions, error: \(error)")
        }
    }
    
    
    /// Fetches all saved tags, uses background
    private func fetchTags() async {
        let descriptor = FetchDescriptor<Tag>()
        do {
            let fetchedTags = try await dataManager.fetchFromBackground(descriptor)
            allTags = fetchedTags
        } catch {
            print("StatisticsViewModel: Unable to fetch tags, error: \(error)")
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
            print("StatisticsViewModel: Unable to fetch Balance Accounts, error: \(error)")
        }
    }
}

//MARK: - Extensions for CustomTabViewModelDelegate
extension StatisticsViewModel: CustomTabViewModelDelegate {
    var id: String {
        "StatisticsViewModel"
    }
    
    func addButtonPressed() {
        return
    }
    
    func didUpdateData(for dataType: SettingsSectionAndDataType, from tabView: TabViewType) {
        if tabView == .welcomeView {
            Task { @MainActor in
                balanceAccountToFilter = dataManager.getDefaultBalanceAccount() ?? .emptyBalanceAccount
            }
            return
        }
        
        guard tabView != .statisticsView else { return }
        switch dataType {
        case .categories:
            isTransactionUpdatedFromAnotherView = true
        case .balanceAccounts:
            isTransactionUpdatedFromAnotherView = true
        case .tags:
            isTransactionUpdatedFromAnotherView = true
        case .transactions:
            isTransactionUpdatedFromAnotherView = true
            Task { @MainActor in
                if isViewDisplayed {
                    try await Task.sleep(for: .seconds(0.3))
                    refreshDataIfNeeded()
                }
            }
        case .appearance:
            return
        case .data:
            isTransactionUpdatedFromAnotherView = true
            if tabView == .settingsView {
                Task { @MainActor in
                    cleanData()
                }
            }
        case .budgets:
            return
        case .notifications:
            break
        }
    }
}

//MARK: - Extension for TagsViewModelDelegate
extension StatisticsViewModel: TagsViewModelDelegate {
    func didDeleteTag() {
        Task {
            await fetchTags()
            calculateTagsTotal()
        }
    }
    
    func didDeleteTagWithTransactions() {
        refreshData()
    }
    
    func didAddTag() {
        Task {
            await fetchTags()
        }
    }
    
    func didUpdatedTag() {
        Task {
            await fetchTags()
            calculateTagsTotal()
        }
    }
}

//MARK: - Extension for TransactionListViewModelDelegate
extension StatisticsViewModel: TransactionListViewModelDelegate {
    func didUpdatedTransaction() {
        isTransactionUpdatedFromAnotherView = true
        delegate?.didUpdatedTransactionsListFromStatistics()
    }
}
