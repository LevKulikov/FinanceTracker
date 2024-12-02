//
//  AdvancedAnalyticsViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 29.11.2024.
//

import SwiftData
import SwiftUI

final class AdvancedAnalyticsViewModel: ObservableObject, @unchecked Sendable {
    enum TaskError: Error {
        case taskCancelled
    }
    //MARK: - Properties
    private let dataManager: any DataManagerProtocol
    private var loadingTransactionsTaskGroup: ThrowingTaskGroup<[Transaction], any Error>?
    private var transactions: [Transaction] = []
    
    //MARK: Published properties
    @MainActor @Published var showAnalytics: Bool = false
    @MainActor @Published var showCurrencySelection: Bool = false
    @MainActor @Published var noTransactions: Bool = false
    @MainActor @Published private(set) var searchConfigurations: [SearchConfiguration] = []
    @MainActor @Published private(set) var isLoadingTransactions: Bool = false
    @MainActor @Published private(set) var isLoadingOtherData: Bool = false
    @MainActor @Published private(set) var currencies: [String] = []
    @MainActor @Published private(set) var selectedCurrency: String = ""
    @MainActor @Published private(set) var allCategories: [Category] = []
    @MainActor @Published private(set) var allTags: [Tag] = []
    @MainActor @Published private(set) var allBalanceAccounts: [BalanceAccount] = []
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
    }
    
    //MARK: - Methods
    func getAnalytics() {
        Task {
            do {
                try await fetchAllTransactions()
                await extractCurrencies()
                
                let currs = await currencies
                if currs.count > 1 {
                    await MainActor.run { showCurrencySelection = true }
                } else {
                    guard let currency = currs.first else {
                        await MainActor.run { noTransactions = true }
                        return
                    }
                    
                    await MainActor.run {
                        selectedCurrency = currency
                        showAnalytics = true
                    }
                }
            } catch {
                print("AdvancedAnalyticsViewModel: error fetching transactions: \(error)")
            }
        }
    }
    
    func fetchOtherData(errorHandler: (@MainActor @Sendable (Error) -> Void)? = nil) {
        // create local error handler to convert MainActro error handler to universal
        let localErrorHandler: (@Sendable (Error) -> Void) = { error in
            Task { @MainActor in
                errorHandler?(error)
            }
        }
        
        Task {
            await MainActor.run {
                isLoadingOtherData = true
            }
            
            await withTaskGroup(of: Void.self) { taskGroup in
                // Fetch categories
                taskGroup.addTask { [weak self] in
                    print("AdvancedAnalyticsViewModel: start fetching categories")
                    await self?.fetchCategories(errorHandler: localErrorHandler)
                    print("AdvancedAnalyticsViewModel: end fetching categories")
                }
                // Fetch tags
                taskGroup.addTask { [weak self] in
                    print("AdvancedAnalyticsViewModel: start fetching tags")
                    await self?.fetchTags(errorHandler: localErrorHandler)
                    print("AdvancedAnalyticsViewModel: end fetching tags")
                }
                // Fetch balance accounts
                taskGroup.addTask { [weak self] in
                    print("AdvancedAnalyticsViewModel: start fetching balance accounts")
                    await self?.fetchBalanceAccounts(errorHandler: localErrorHandler)
                    print("AdvancedAnalyticsViewModel: end fetching balance accounts")
                }
                // Wait until all data is fetched
                await taskGroup.waitForAll()
            }
            
            await MainActor.run {
                isLoadingOtherData = false
            }
        }
    }
    
    func cancelFetching() {
        loadingTransactionsTaskGroup?.cancelAll()
    }
    
    @MainActor
    func addConfiguration(_ configuration: SearchConfiguration) {
        searchConfigurations.append(configuration)
    }
    
    @MainActor
    func updateConfiguration(_ configuration: SearchConfiguration) {
        guard let index = searchConfigurations.firstIndex(where: { $0.id == configuration.id }) else {
            print("AdvancedAnalyticsViewModel: updateConfiguration: configuration not found")
            return
        }
        searchConfigurations[index] = configuration
    }
    
    @MainActor
    func removeConfiguration(_ configuration: SearchConfiguration) {
        guard let index = searchConfigurations.firstIndex(where: {$0.id == configuration.id }) else {
            print("AdvancedAnalyticsViewModel: removeConfiguration: configuration not found")
            return
        }
        searchConfigurations.remove(at: index)
    }
    
    @MainActor
    func removeAllConfigurations() {
        searchConfigurations = []
    }
    
    @MainActor
    func duplicateConfiguration(_ configuration: SearchConfiguration) {
        let copyConfiguration = SearchConfiguration(
            filterTransactionType: configuration.filterTransactionType,
            filterBalanceAccount: configuration.filterBalanceAccount,
            filterCategory: configuration.filterCategory,
            filterTags: configuration.filterTags,
            dateFilterType: configuration.dateFilterType,
            filterDate: configuration.filterDate,
            filterDateStart: configuration.filterDateStart,
            filterDateEnd: configuration.filterDateEnd
        )
        
        addConfiguration(copyConfiguration)
    }
    
    @MainActor
    func selectCurrency(_ currencyString: String) {
        selectedCurrency = currencyString
        showAnalytics = true
    }
    
    @MainActor
    func getAnalyticsPage() -> some View {
        FTFactory.shared.createProvidedStatisticsView(transactions: transactions, currency: selectedCurrency)
    }
    
    //MARK: Private methods
    private func fetchAllTransactions(errorHandler: (@Sendable (Error) -> Void)? = nil) async throws {
        let configurations = await searchConfigurations
        
        await MainActor.run { isLoadingTransactions = true }
        
        do {
            try await withThrowingTaskGroup(of: [Transaction].self) { taskGroup in
                loadingTransactionsTaskGroup = taskGroup
                defer { loadingTransactionsTaskGroup = nil }
                
                for configuration in configurations {
                    taskGroup.addTask { [weak self] in
                        guard let self else { return [] }
                        
                        try Task.checkCancellation()
                        print("AdvancedAnalyticsViewModel: start fetching transactions for configuration")
                        let fetchedTransactions = await self.fetchTransactions(configuration: configuration, errorHandler: errorHandler)
                        
                        try Task.checkCancellation()
                        print("AdvancedAnalyticsViewModel: start filtering transactions for configuration")
                        let filteredTransactions = await self.filterTransactions(fetchedTransactions, with: configuration)
                        return filteredTransactions
                    }
                }
                
                guard !taskGroup.isCancelled else {
                    print("AdvancedAnalyticsViewModel: fetchAllTransactions: taskGroup is cancelled")
                    throw TaskError.taskCancelled
                }
                
                var transactions: [Transaction] = []
                for try await fetchedTransactions in taskGroup {
                    transactions.append(contentsOf: fetchedTransactions)
                }
                
                guard !taskGroup.isCancelled else {
                    print("AdvancedAnalyticsViewModel: fetchAllTransactions: taskGroup is cancelled")
                    throw TaskError.taskCancelled
                }
                
                self.transactions = getUniqueAndSortedTransactions(transactions)
            }
        } catch {
            await MainActor.run { isLoadingTransactions = false }
            throw error
        }
        
        await MainActor.run { isLoadingTransactions = false }
    }
    
    private func fetchTransactions(configuration: SearchConfiguration, errorHandler: (@Sendable (Error) -> Void)? = nil) async -> [Transaction] {
        let dateRange = getDateFilterRange(configuration: configuration)
        let lowerBound = dateRange.lowerBound
        let upperBound = dateRange.upperBound
        
        let isBalanceAccountFilterEnabled: Bool = configuration.filterBalanceAccount != nil
        let copyBalanceAccountId = configuration.filterBalanceAccount?.persistentModelID
        
        let isCategoryFilterEnabled: Bool = configuration.filterCategory != nil
        let copyCategoryId = configuration.filterCategory?.persistentModelID
        
        // Method's predicate does not filter by tags (beacause of difficult logic, not for predicate) and transaction type (because of error of predicate)
        let predicate = #Predicate<Transaction> { transaction in
            if (lowerBound...upperBound).contains(transaction.date) {
                if !isBalanceAccountFilterEnabled || transaction.balanceAccount?.persistentModelID == copyBalanceAccountId {
                    if !isCategoryFilterEnabled || transaction.category?.persistentModelID == copyCategoryId {
                        return true
                    } else {
                        return false
                    }
                } else {
                    return false
                }
            } else {
                return false
            }
        }
        
        let descriptor = FetchDescriptor<Transaction>(predicate: predicate)
        
        do {
            let fetchedTransactions = try await dataManager.fetchFromBackground(descriptor)
            return fetchedTransactions
        } catch {
            errorHandler?(error)
            return []
        }
    }
    
    private func fetchCategories(errorHandler: (@Sendable (Error) -> Void)? = nil) async {
        guard let fetchedCategories: [Category] = await fetch(sortBy: [SortDescriptor<Category>(\.placement)]) else {
            errorHandler?(FetchErrors.unableToFetchCategories)
            return
        }
        
        await MainActor.run {
            self.allCategories = fetchedCategories
        }
    }
    
    private func fetchTags(errorHandler: (@Sendable (Error) -> Void)? = nil) async {
        guard let fetchedTags: [Tag] = await fetch() else {
            errorHandler?(FetchErrors.unableToFetchTags)
            return
        }
        
        await MainActor.run {
            self.allTags = fetchedTags
        }
    }
    
    private func fetchBalanceAccounts(errorHandler: (@Sendable (Error) -> Void)? = nil) async {
        guard let fetchedBalanceAccounts: [BalanceAccount] = await fetch() else {
            errorHandler?(FetchErrors.unableToFetchBalanceAccounts)
            return
        }
        
        await MainActor.run {
            self.allBalanceAccounts = fetchedBalanceAccounts
        }
    }
    
    private func fetch<T>(withPredicate: Predicate<T>? = nil, sortBy: [SortDescriptor<T>] = []) async -> [T]? where T: PersistentModel, T: Sendable {
        let descriptor = FetchDescriptor<T>(
            predicate: withPredicate,
            sortBy: sortBy
        )
        
        do {
            let fetchedItems = try await dataManager.fetchFromBackground(descriptor)
            return fetchedItems
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    private func getDateFilterRange(configuration: SearchConfiguration) -> ClosedRange<Date> {
        let filterDate = configuration.filterDate
        
        switch configuration.dateFilterType {
        case .day:
            let startDate = filterDate.startOfDay()
            let endDate = filterDate.endOfDay() ?? filterDate
            return startDate...endDate
        case .week:
            let startDate = filterDate.startOfWeek() ?? filterDate
            let endDate = filterDate.endOfWeek() ?? filterDate
            return startDate...endDate
        case .month:
            let startDate = filterDate.startOfMonth() ?? filterDate
            let endDate = filterDate.endOfMonth() ?? filterDate
            return startDate...endDate
        case .year:
            let startDate = filterDate.startOfYear() ?? filterDate
            let endDate = filterDate.endOfYear() ?? filterDate
            return startDate...endDate
        case .customDateRange:
            let startDate = configuration.filterDateStart.startOfDay()
            let endDate = configuration.filterDateEnd.endOfDay() ?? configuration.filterDateEnd
            return startDate...endDate
        }
    }
    
    /// Filters by tags and transaction type
    private func filterTransactions(_ transactions: [Transaction], with configuration: SearchConfiguration) async -> [Transaction] {
        return transactions.filter { transaction in
            var isSameType = true
            if let transactionType = configuration.filterTransactionType.binaryTransactionType {
                isSameType = transaction.type == transactionType
            }
            
            var isSameTags = true
            if !configuration.filterTags.isEmpty {
                let sortedFilterTagsId = configuration.filterTags.sorted { $0.name < $1.name }.map(\.id)
                isSameTags = transaction.tags.sorted { $0.name < $1.name }.map { $0.id }.contains(sortedFilterTagsId)
            }
            
            return isSameType && isSameTags
        }
    }
    
    private func getUniqueAndSortedTransactions(_ transactions: [Transaction]) -> [Transaction] {
        let uniqueTransactions = Set(transactions)
        return Array(uniqueTransactions).sorted { $0.date > $1.date }
    }
    
    private func extractCurrencies() async {
        let uniqueCurrencies = Set(transactions.compactMap(\.balanceAccount?.currency))
        await MainActor.run {
            currencies = Array(uniqueCurrencies)
        }
    }
}
