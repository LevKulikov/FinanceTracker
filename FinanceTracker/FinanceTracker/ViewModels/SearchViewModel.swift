//
//  SearchViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 27.06.2024.
//

import Foundation
@preconcurrency import SwiftData
import SwiftUI

protocol SearchViewModelDelegate: AnyObject {
    func didUpdatedTransactionsList()
    
    func hideTabBar(_ hide: Bool)
}

enum DateFilterType: LocalizedStringResource, CaseIterable, Identifiable {
    case day = "For a day"
    case week = "For a week"
    case month = "For a month"
    case year = "For a year"
    case customDateRange = "Date range"
    
    var id: Self {
        return self
    }
}

struct TransactionGroupedData: Identifiable {
    let id: String = UUID().uuidString
    let date: Date
    let transactions: [Transaction]
}

final class SearchViewModel: ObservableObject, @unchecked Sendable {
    struct Configuration {
        var filterTransactionType: TransactionFilterTypes = .both
        var filterBalanceAccount: BalanceAccount?
        var filterCategory: Category?
        var filterTags: [Tag] = []
        var dateFilterType: DateFilterType = .month
        var filterDate: Date = .now
        var filterDateStart: Date = .now
        var filterDateEnd: Date = .now
    }
    
    //MARK: - Properties
    weak var delegate: (any SearchViewModelDelegate)?
    
    //MARK: Private props
    private let dataManager: any DataManagerProtocol
    private let calendar = Calendar.current
    private var searchDispatchWorkItem: DispatchWorkItem?
    private var allTransactions: [Transaction] = []
    /// Not grouped, only filtered, used for search filter
    private var filteredTransaction: [Transaction] = []
    private var allCategories: [Category] = []
    /// For transactions predicate
    private var dateFilterRange: ClosedRange<Date> {
        switch dateFilterType {
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
            let startDate = filterDateStart.startOfDay()
            let endDate = filterDateEnd.endOfDay() ?? filterDateEnd
            return startDate...endDate
        }
    }
    
    //MARK: UI props
    // To filter
    @Published var searchText: String = "" {
        didSet {
            searchDispatchWorkItem?.cancel()
            searchDispatchWorkItem = DispatchWorkItem { [weak self] in
                self?.filterTransactionsWithSearch()
            }
            if let searchDispatchWorkItem {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: searchDispatchWorkItem)
            }
        }
    }
    @Published var filterTransactionType: TransactionFilterTypes = .both {
        didSet {
            guard filterTransactionType != oldValue else { return }
            if let filterCategoryType = filterCategory?.type, let selectedType = filterTransactionType.binaryTransactionType {
                if filterCategoryType != selectedType {
                    filterCategory = nil
                    return
                }
            }
            filterAndSetTransactions()
        }
    }
    @Published var filterBalanceAccount: BalanceAccount? = nil {
        didSet {
            guard filterBalanceAccount != oldValue else { return }
            filterAndSetTransactions()
        }
    }
    @Published var filterCategory: Category? = nil {
        didSet {
            guard filterCategory != oldValue else { return }
            filterAndSetTransactions()
        }
    }
    @Published var filterTags: [Tag] = [] {
        didSet {
            guard filterTags != oldValue else { return }
            filterAndSetTransactions()
        }
    }
    @Published var dateFilterType: DateFilterType = .month {
        didSet {
            guard dateFilterType != oldValue else { return }
            Task {
                await fetchTransactions()
                filterAndSetTransactions()
            }
        }
    }
    @Published var filterDate: Date = .now {
        didSet {
            guard filterDate != oldValue else { return }
            Task {
                await fetchTransactions()
                filterAndSetTransactions()
            }
        }
    }
    @Published var filterDateStart: Date = .now {
        didSet {
            guard filterDateStart != oldValue else { return }
            Task {
                await fetchTransactions()
                filterAndSetTransactions()
            }
        }
    }
    @Published var filterDateEnd: Date = .now {
        didSet {
            guard filterDateEnd != oldValue else { return }
            Task {
                await fetchTransactions()
                filterAndSetTransactions()
            }
        }
    }
    
    //Filter data arrays
    @Published private(set) var allBalanceAccounts: [BalanceAccount] = []
    @Published private(set) var allTags: [Tag] = []
    var filterCategories: [Category] {
        guard filterTransactionType != .both else { return allCategories }
        
        return allCategories.filter { category in
            switch filterTransactionType {
            case .both:
                return true
            case .spending:
                return category.type == .spending
            case .income:
                return category.type == .income
            }
        }
    }
    
    //For UI
    @Published private(set) var isListCalculating: Bool = false
    @Published private(set) var filteredTransactionGroups: [TransactionGroupedData] = []
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
        fetchAllData(competionHandler:  { [weak self] in
            self?.filterAndSetTransactions()
        })
    }
    
    init(dataManager: some DataManagerProtocol, configuration: Configuration) {
        self.dataManager = dataManager
        self._filterTransactionType = Published(wrappedValue: configuration.filterTransactionType)
        self._filterBalanceAccount = Published(wrappedValue: configuration.filterBalanceAccount)
        self._filterCategory = Published(wrappedValue: configuration.filterCategory)
        self._filterTags = Published(wrappedValue: configuration.filterTags)
        self._dateFilterType = Published(wrappedValue: configuration.dateFilterType)
        self._filterDate = Published(wrappedValue: configuration.filterDate)
        self._filterDateStart = Published(wrappedValue: configuration.filterDateStart)
        self._filterDateEnd = Published(wrappedValue: configuration.filterDateEnd)
        fetchAllData(competionHandler:  { [weak self] in
            self?.filterAndSetTransactions()
        })
    }
    
    //MARK: - Methods
    func addRemoveTag(_ tag: Tag) {
        if filterTags.contains(tag) {
            withAnimation {
                filterTags.removeAll {
                    $0 == tag
                }
            }
        } else {
            withAnimation {
                filterTags.append(tag)
            }
        }
    }
    
    func hideTabBar(_ hide: Bool) {
        delegate?.hideTabBar(hide)
    }
    
    @MainActor
    func getTransactionView(for transaction: Transaction, namespace: Namespace.ID) -> some View {
        return FTFactory.shared.createAddingSpendIcomeView(dataManager: dataManager, threadToUse: .global, transactionType: transaction.type ?? TransactionsType(rawValue: transaction.typeRawValue)!, balanceAccount: transaction.balanceAccount ?? .emptyBalanceAccount, forAction: .constant(.update(transaction)), namespace: namespace, delegate: self)
    }
    
    func refetchData() {
        fetchAllData(competionHandler:  { [weak self] in
            self?.filterAndSetTransactions()
        })
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        Task {
            try await dataManager.deleteTransactionFromBackground(transaction)
            await fetchTransactions()
            delegate?.didUpdatedTransactionsList()
            filterAndSetTransactions()
        }
    }
    
    //MARK: Private props
    private func filterAndSetTransactions() {
        Task { @MainActor in
            isListCalculating = true
        }
        
        Task.detached(priority: .high) { [weak self] in
            guard let self else { return }
            
            let filteredData = allTransactions
                //Filter by transaction type
                .filter { trans in
                    switch self.filterTransactionType {
                    case .both:
                        return true
                    case .spending:
                        return trans.type == .spending
                    case .income:
                        return trans.type == .income
                    }
                }
                //Filter by balance account, category and tags
                //Uses id to compare because of different context used for fetching
                .filter { trans in
                    var sameBA = true
                    if let filterBA = self.filterBalanceAccount {
                        sameBA = trans.balanceAccount?.id == filterBA.id
                    }
                    
                    var sameCategory = true
                    if let filterCat = self.filterCategory {
                        sameCategory = trans.category?.id == filterCat.id
                    }
                    
                    var containsNeededTag = true
                    if !self.filterTags.isEmpty {
                        containsNeededTag = trans.tags.sorted { $0.name < $1.name }.map { $0.id }.contains(self.filterTags.sorted { $0.name < $1.name }.map { $0.id })
                    }
                    
                    return (sameBA && sameCategory && containsNeededTag)
                }
            
            self.filteredTransaction = filteredData
            var searchData = filteredData
            if !self.searchText.isEmpty {
                searchData = self.getFilteredTransactionWithSearchText(arrayToFilter: searchData)
            }
            
            let sortedGroupedData = self.groupAndSortTransactionArray(searchData)
            
            await MainActor.run {
                self.isListCalculating = false
                withAnimation {
                    self.filteredTransactionGroups = sortedGroupedData
                }
            }
        }
    }
    
    private func filterTransactionsWithSearch() {
        Task { @MainActor in
            isListCalculating = true
        }
        
        Task.detached(priority: .high) { [weak self] in
            guard let self else { return }
            
            if !self.searchText.isEmpty {
                let searchFiltered = self.getFilteredTransactionWithSearchText(arrayToFilter: filteredTransaction)
                let groups = self.groupAndSortTransactionArray(searchFiltered)
                
                DispatchQueue.main.async {
                    self.isListCalculating = false
                    withAnimation {
                        self.filteredTransactionGroups = groups
                    }
                }
            } else {
                let groups = self.groupAndSortTransactionArray(filteredTransaction)
                
                await MainActor.run {
                    self.isListCalculating = false
                    withAnimation {
                        self.filteredTransactionGroups = groups
                    }
                }
            }
        }
    }
    
    private func getFilteredTransactionWithSearchText(arrayToFilter: [Transaction]) -> [Transaction] {
        return arrayToFilter
            .filter { trans in
                // If searchText is number
                var copyString = self.searchText
                
                if copyString.contains(",") {
                    copyString.replace(",", with: ".")
                }
                
                if copyString.contains(" ") {
                    copyString.replace(" ", with: "")
                }
                
                if let floatSearchNumber = Float(copyString) {
                    return trans.value == floatSearchNumber
                }
                
                // if searchText is text
                guard let balanceAccount = trans.balanceAccount, let category = trans.category else { return false }
                
                let baNameHasSuchString = balanceAccount.name.localizedCaseInsensitiveContains(self.searchText)
                let currencyHasSuchString = balanceAccount.currency.localizedCaseInsensitiveContains(self.searchText)
                let catNameHasSuchString = category.name.localizedCaseInsensitiveContains(self.searchText)
                let tagsHaveSuchString = trans.tags.map { $0.name }.joined().localizedCaseInsensitiveContains(self.searchText)
                let commentHasSuchString = trans.comment.localizedCaseInsensitiveContains(self.searchText)
                
                return (baNameHasSuchString || currencyHasSuchString || catNameHasSuchString || tagsHaveSuchString || commentHasSuchString)
            }
    }
    
    private func groupAndSortTransactionArray(_ array: [Transaction]) -> [TransactionGroupedData] {
        return array
            .grouped { trans in
                let year = self.calendar.component(.year, from: trans.date)
                let month = self.calendar.component(.month, from: trans.date)
                let day = self.calendar.component(.day, from: trans.date)
                return DateComponents(year: year, month: month, day: day)
            }
            .map { dictTuple in
                let date = self.calendar.date(from: dictTuple.key) ?? .now
                return TransactionGroupedData(date: date, transactions: dictTuple.value)
            }
            .sorted { $0.date > $1.date }
    }
    
    private func fetchAllData(errorHandler: (@Sendable (Error) -> Void)? = nil, competionHandler: (@Sendable () -> Void)? = nil) {
        Task {
            await fetchCategories(errorHandler: errorHandler)
            await fetchTags(errorHandler: errorHandler)
            await fetchBalanceAccounts(errorHandler: errorHandler)
            Task.detached(priority: .background) { [weak self] in
                await self?.fetchTransactions(errorHandler: errorHandler)
                competionHandler?()
            }
        }
    }
    
    private func fetchTransactions(errorHandler: ((Error) -> Void)? = nil) async {
        let lowerBound = dateFilterRange.lowerBound
        let upperBound = dateFilterRange.upperBound
        let predicate = #Predicate<Transaction> {
            (lowerBound...upperBound).contains($0.date)
        }
        
        let descriptor = FetchDescriptor<Transaction>(predicate: predicate)
        do {
            let fetchedTransactions: [Transaction] = try await dataManager.fetchFromBackground(descriptor)
            allTransactions = fetchedTransactions
        } catch {
            errorHandler?(error)
        }
    }
    
    private func fetchCategories(errorHandler: (@Sendable (Error) -> Void)? = nil) async {
        guard let fetchedCategories: [Category] = await fetch(sortBy: [SortDescriptor<Category>(\.placement)]) else {
            errorHandler?(FetchErrors.unableToFetchCategories)
            return
        }
        
        Task { @MainActor in
            withAnimation(.snappy) {
                self.allCategories = fetchedCategories
            }
        }
    }
    
    private func fetchTags(errorHandler: (@Sendable (Error) -> Void)? = nil) async {
        guard let fetchedTags: [Tag] = await fetch() else {
            errorHandler?(FetchErrors.unableToFetchTags)
            return
        }
        
        Task { @MainActor in
            withAnimation(.snappy) {
                self.allTags = fetchedTags
            }
        }
    }
    
    private func fetchBalanceAccounts(errorHandler: (@Sendable (Error) -> Void)? = nil) async {
        guard let fetchedBalanceAccounts: [BalanceAccount] = await fetch() else {
            errorHandler?(FetchErrors.unableToFetchBalanceAccounts)
            return
        }
        
        Task { @MainActor in
            withAnimation(.snappy) {
                self.allBalanceAccounts = fetchedBalanceAccounts
            }
        }
    }
    
    private func fetch<T>(withPredicate: Predicate<T>? = nil, sortBy: [SortDescriptor<T>] = []) async -> [T]? where T: PersistentModel, T: Sendable {
        let descriptor = FetchDescriptor<T>(
            predicate: withPredicate,
            sortBy: sortBy
        )
        
        do {
            let fetchedItems = try await dataManager.fetch(descriptor)
            return fetchedItems
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

//MARK: - Extensions
extension SearchViewModel: CustomTabViewModelDelegate {
    var id: String {
        "SearchViewModel"
    }
    
    func addButtonPressed() {
        return
    }
    
    func didUpdateData(for dataType: SettingsSectionAndDataType, from tabView: TabViewType) {
        guard tabView != .searchView else { return }
        
        switch dataType {
        case .balanceAccounts:
            Task {
                await fetchBalanceAccounts()
            }
            
        case .categories:
            Task {
                await fetchCategories()
            }
            
        case .tags:
            Task {
                await fetchTags()
            }
            
        case .transactions:
            Task {
                await fetchTransactions()
                filterAndSetTransactions()
            }
            
        case .data:
            fetchAllData(competionHandler:  { [weak self] in
                self?.filterAndSetTransactions()
            })
            
        case .budgets:
            break
        case .appearance:
            break
        case .notifications:
            break
        }
    }
}

extension SearchViewModel: AddingSpendIcomeViewModelDelegate {
    func addedNewTransaction(_ transaction: Transaction) {
        delegate?.didUpdatedTransactionsList()
        Task {
            await fetchTransactions()
            filterAndSetTransactions()
        }
    }
    
    func updateTransaction(_ transaction: Transaction) {
        delegate?.didUpdatedTransactionsList()
        Task {
            await fetchTransactions()
            filterAndSetTransactions()
        }
    }
    
    func deletedTransaction(_ transaction: Transaction) {
        delegate?.didUpdatedTransactionsList()
        Task {
            await fetchTransactions()
            filterAndSetTransactions()
        }
    }
    
    func transactionsTypeReselected(to newType: TransactionsType) {
        return
    }
    
    func categoryUpdated() {
        delegate?.didUpdatedTransactionsList()
        Task {
            await fetchCategories()
        }
    }
}
