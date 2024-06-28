//
//  SearchViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 27.06.2024.
//

import Foundation
import SwiftData
import SwiftUI

protocol SearchViewModelDelegate: AnyObject {
    func didUpdatedTransactionsList()
}

enum DateFilterType: String, CaseIterable {
    case day = "For a day"
    case week = "For a week"
    case month = "For a month"
    case year = "For a year"
    case customDateRange = "Date range"
}

struct TransactionGroupedData: Identifiable {
    let id: String = UUID().uuidString
    let date: Date
    let transactions: [Transaction]
}

final class SearchViewModel: ObservableObject {
    //MARK: - Properties
    weak var delegate: (any SearchViewModelDelegate)?
    
    //MARK: Private props
    private let dataManager: any DataManagerProtocol
    private let calendar = Calendar.current
    private var searchDispatchWorkItem: DispatchWorkItem?
    private var allTransactions: [Transaction] = []
    private var allCategories: [Category] = []
    
    //MARK: UI props
    // To filter
    @Published var searchText: String = "" {
        didSet {
            searchDispatchWorkItem?.cancel()
            searchDispatchWorkItem = DispatchWorkItem { [weak self] in
                self?.filterAndSetTransactions()
            }
            if let searchDispatchWorkItem {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: searchDispatchWorkItem)
            }
        }
    }
    @Published var filterTransactionType: TransactionFilterTypes = .both {
        didSet {
            guard filterTransactionType != oldValue else { return }
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
            filterAndSetTransactions()
        }
    }
    @Published var filterDate: Date = .now {
        didSet {
            guard filterDate != oldValue else { return }
            filterAndSetTransactions()
        }
    }
    @Published var filterDateStart: Date = .now {
        didSet {
            guard filterDateStart != oldValue else { return }
            filterAndSetTransactions()
        }
    }
    @Published var filterDateEnd: Date = .now {
        didSet {
            guard filterDateEnd != oldValue else { return }
            filterAndSetTransactions()
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
    
    //MARK: Private props
    private func filterAndSetTransactions() {
        DispatchQueue.main.async { [weak self] in
            self?.isListCalculating = true
        }
        
        DispatchQueue.global().async { [weak self] in
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
                .filter { trans in
                    var sameBA = true
                    if let filterBA = self.filterBalanceAccount {
                        sameBA = trans.balanceAccount == filterBA
                    }
                    
                    var sameCategory = true
                    if let filterCat = self.filterCategory {
                        sameCategory = trans.category == filterCat
                    }
                    
                    var containsNeededTag = true
                    if !self.filterTags.isEmpty {
                        containsNeededTag = trans.tags.contains(self.filterTags)
                    }
                    
                    return (sameBA && sameCategory && containsNeededTag)
                }
                //Filter by date
                .filter { trans in
                    switch self.dateFilterType {
                    case .day:
                        return self.calendar.isDate(trans.date, equalTo: self.filterDate, toGranularity: .day)
                    case .week:
                        let startOfWeekOfTrans = trans.date.startOfWeek() ?? .now
                        let startOfWeekOfFilter = self.filterDate.startOfWeek() ?? .now
                        return self.calendar.isDate(startOfWeekOfTrans, equalTo: startOfWeekOfFilter, toGranularity: .day)
                    case .month:
                        return self.calendar.isDate(trans.date, equalTo: self.filterDate, toGranularity: .month)
                    case .year:
                        return self.calendar.isDate(trans.date, equalTo: self.filterDate, toGranularity: .year)
                    case .customDateRange:
                        let lowerBound = self.calendar.startOfDay(for: self.filterDateStart)
                        let higherBound = self.calendar.startOfDay(for: self.calendar.date(byAdding: .day, value: 1, to: self.filterDateEnd) ?? self.filterDateEnd)
                        return (lowerBound...higherBound).contains(trans.date)
                    }
                }
            
            var searchData = filteredData
            if !self.searchText.isEmpty {
                searchData = searchData
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
                        
                        let baNameHasSuchString = trans.balanceAccount.name.contains(self.searchText)
                        let catNameHasSuchString = trans.category.name.contains(self.searchText)
                        let tagsHaveSuchString = trans.tags.map { $0.name }.joined().contains(self.searchText)
                        let commentHasSuchString = trans.comment.contains(self.searchText)
                        
                        return (baNameHasSuchString || catNameHasSuchString || tagsHaveSuchString || commentHasSuchString)
                    }
            }
            
            let sortedGroupedData = searchData
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
            
            DispatchQueue.main.async {
                self.isListCalculating = false
                withAnimation {
                    self.filteredTransactionGroups = sortedGroupedData
                }
            }
        }
    }
    
    private func fetchAllData(errorHandler: ((Error) -> Void)? = nil, competionHandler: (() -> Void)? = nil) {
        Task {
            await fetchTransactions(errorHandler: errorHandler)
            await fetchCategories(errorHandler: errorHandler)
            await fetchTags(errorHandler: errorHandler)
            await fetchBalanceAccounts(errorHandler: errorHandler)
            competionHandler?()
        }
    }
    
    private func fetchTransactions(errorHandler: ((Error) -> Void)? = nil) async {
        guard let fetchedTransactions: [Transaction] = await fetch() else {
            errorHandler?(FetchErrors.unableToFetchTransactions)
            return
        }
        
        allTransactions = fetchedTransactions
    }
    
    @MainActor
    private func fetchCategories(errorHandler: ((Error) -> Void)? = nil) async {
        guard let fetchedCategories: [Category] = await fetch() else {
            errorHandler?(FetchErrors.unableToFetchCategories)
            return
        }
        
        withAnimation(.snappy) {
            allCategories = fetchedCategories
        }
    }
    
    @MainActor
    private func fetchTags(errorHandler: ((Error) -> Void)? = nil) async {
        guard let fetchedTags: [Tag] = await fetch() else {
            errorHandler?(FetchErrors.unableToFetchTags)
            return
        }
        
        withAnimation(.snappy) {
            allTags = fetchedTags
        }
    }
    
    @MainActor
    private func fetchBalanceAccounts(errorHandler: ((Error) -> Void)? = nil) async {
        guard let fetchedBalanceAccounts: [BalanceAccount] = await fetch(sortWithString: \.name) else {
            errorHandler?(FetchErrors.unableToFetchBalanceAccounts)
            return
        }
        
        withAnimation(.snappy) {
            allBalanceAccounts = fetchedBalanceAccounts
        }
    }
    
    private func fetch<T>(withPredicate: Predicate<T>? = nil, sortWithString keyPath: KeyPath<T, String>? = nil) async -> [T]? where T: PersistentModel {
        let descriptor = FetchDescriptor<T>(
            predicate: withPredicate,
            sortBy: keyPath == nil ? [] : [SortDescriptor(keyPath!)]
        )
        
        do {
            var fetchedItems = try await dataManager.fetch(descriptor)
            if keyPath == nil {
                fetchedItems.reverse()
            }
            return fetchedItems
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}
