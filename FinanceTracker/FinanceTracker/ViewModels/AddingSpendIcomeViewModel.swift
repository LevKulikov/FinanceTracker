//
//  AddingSpendIcomeViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 29.05.2024.
//

import Foundation
@preconcurrency import SwiftData
import SwiftUI

protocol AddingSpendIcomeViewModelDelegate: AnyObject {
    func addedNewTransaction(_ transaction: Transaction)
    func updateTransaction(_ transaction: Transaction)
    func deletedTransaction(_ transaction: Transaction)
    func transactionsTypeReselected(to newType: TransactionsType)
    func categoryUpdated()
}

enum FetchErrors: Error {
    case unableToFetchTransactions
    case unableToFetchCategories
    case unableToFetchTags
    case unableToFetchBalanceAccounts
}

final class AddingSpendIcomeViewModel: ObservableObject, @unchecked Sendable {
    enum SaveErrors: Error {
        case categoryIsNil
        case valueIsZero
        case contextSaveError
        
        var saveErrorLocalizedDescription: LocalizedStringResource {
            switch self {
            case .categoryIsNil:
                return "Category is not selected"
            case .valueIsZero:
                return "Value cannot be zero or empy"
            case .contextSaveError:
                return "Some save error occured"
            }
        }
    }
    
    //MARK: Properties
    private let dataManager: any DataManagerProtocol
    private let dataThread: DataManager.DataThread
    weak var delegate: (any AddingSpendIcomeViewModelDelegate)?
    var action: ActionWithTransaction = .none {
        didSet {
            switch action {
            case .add(let providedDate):
                date = providedDate
            case .update(let transaction):
                transactionToUpdate = transaction
                setTransactionPropertiesToViewModel(transaction: transaction)
            case .none:
                break
            }
            setDateArray()
        }
    }
    var availableDateRange: ClosedRange<Date> {
        Date(timeIntervalSince1970: 0)...Date.now
    }
    private(set) var transactionToUpdate: Transaction?
    @Published private(set) var availableCategories: [Category] = []
    @Published private(set) var availableTags: [Tag] = []
    @Published private(set) var availableBalanceAccounts: [BalanceAccount] = []
    @Published private(set) var threeDatesArray: [Date] = []
    @Published var searchTagText: String = ""
    
    //MARK: Transaction Props
    @Published var transactionsTypeSelected: TransactionsType = .spending {
        didSet {
            delegate?.transactionsTypeReselected(to: transactionsTypeSelected)
            category = nil
            Task {
                await fetchCategories()
            }
        }
    }
    @Published var comment: String = ""
    @Published var valueString: String = ""
    @Published var value: Float = 0
    @Published var date: Date = .now {
        didSet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.setDateArray()
            }
        }
    }
    @Published var balanceAccount: BalanceAccount
    @Published var category: Category?
    @Published var tags: [Tag] = [] {
        didSet {
            setSelectedTagsFirstInArray(withDelay: .now() + 1.5)
        }
    }
    
    //MARK: Initializer
    init(dataManager: some DataManagerProtocol, use dataThread: DataManager.DataThread, transactionsTypeSelected: TransactionsType, balanceAccount: BalanceAccount) {
        self.dataManager = dataManager
        self.dataThread = dataThread
        self._transactionsTypeSelected = Published(wrappedValue: transactionsTypeSelected)
        self._balanceAccount = Published(wrappedValue: balanceAccount)
        fetchAllData()
    }
    
    //MARK: Methods
    /// Updates or saves new transaction
    func saveTransaction(completionHanler: (@MainActor (SaveErrors?) -> Void)? = nil) {
        // Field checking
        guard value > 0 else {
            Task { @MainActor in
                completionHanler?(.valueIsZero)
            }
            return
        }
        
        guard let category else {
            Task { @MainActor in
                completionHanler?(.categoryIsNil)
            }
            return
        }
        
        // Saving
        if let transactionToUpdate {
            transactionToUpdate.type = transactionsTypeSelected
            transactionToUpdate.value = value
            transactionToUpdate.setCategory(category)
            transactionToUpdate.setBalanceAccount(balanceAccount)
            transactionToUpdate.date = date
            transactionToUpdate.setTags(tags)
            transactionToUpdate.comment = comment
            Task { @MainActor in
                do {
                    switch dataThread {
                    case .main:
                        try dataManager.save()
                    case .global:
                        try await dataManager.saveFromBackground()
                    }
                    delegate?.updateTransaction(transactionToUpdate)
                } catch {
                    completionHanler?(.contextSaveError)
                }
            }
        } else {
            let newTransaction = Transaction(
                type: transactionsTypeSelected,
                comment: comment,
                value: value,
                date: date,
                balanceAccount: balanceAccount,
                category: category,
                tags: tags
            )
            Task {
                switch dataThread {
                case .main:
                    await dataManager.insert(newTransaction)
                case .global:
                    await dataManager.insertFromBackground(newTransaction)
                }
                delegate?.updateTransaction(newTransaction)
            }
        }
        
        Task { @MainActor in
            completionHanler?(nil)
        }
    }
    
    func addRemoveTag(_ tag: Tag) {
        if tags.contains(tag) {
            withAnimation {
                tags.removeAll {
                    $0 == tag
                }
            }
        } else {
            withAnimation {
                tags.append(tag)
            }
        }
    }
    
    func createNewTag(andSelect: Bool) {
        createNewTag(name: searchTagText, andSelect: andSelect)
    }
    
    func createNewTag(name: String, color: Color? = nil, andSelect: Bool) {
        guard !name.isEmpty else { return }
        
        var colorToSet: Color? = nil
        if let color {
            colorToSet = color
        } else {
            colorToSet = dataManager.tagDefaultColor
        }
        
        let newTag = Tag(name: name, color: colorToSet)
        
        if andSelect {
            addRemoveTag(newTag)
        }
        Task {
            switch dataThread {
            case .main:
                await dataManager.insert(newTag)
            case .global:
                await dataManager.insertFromBackground(newTag)
            }
            await fetchTags()
        }
    }
    
    func deleteUpdatedTransaction(completionHandler: (@MainActor @Sendable () -> Void)?) {
        guard let transactionToUpdate else { return }
        Task {
            switch dataThread {
            case .main:
                await dataManager.deleteTransaction(transactionToUpdate)
            case .global:
                do {
                    try await dataManager.deleteTransactionFromBackground(transactionToUpdate)
                } catch {
                    print("AddingSpendIcomeViewModel: deleteUpdatedTransaction: Error while deleting (from global): \(error)")
                    return
                }
            }
            delegate?.deletedTransaction(transactionToUpdate)
            Task { @MainActor in
                completionHandler?()
            }
        }
    }
    
    @MainActor
    func getAddingCategoryView(action: ActionWithCategory) -> some View {
        return FTFactory.shared.createAddingCategoryView(dataManager: dataManager, transactionType: transactionsTypeSelected, action: action, delegate: self)
    }
    
    @MainActor
    func getAddingBalanceAccountView() -> some View {
        return FTFactory.shared.createAddingBalanceAccauntView(dataManager: dataManager, action: .add, delegate: self)
    }
    
    private func fetchAllData(errorHandler: (@Sendable (Error) -> Void)? = nil) {
        Task {
            await fetchCategories(errorHandler: errorHandler)
            await fetchTags(errorHandler: errorHandler)
            await fetchBalanceAccounts(errorHandler: errorHandler)
        }
    }
    
    @MainActor
    private func fetchCategories(errorHandler: (@Sendable (Error) -> Void)? = nil) async {
        // It is needed to prevent Predicate type convertion error (cannot reference an object property inside of a Predicate)
        let rawValue = transactionsTypeSelected.rawValue
        
        let predicate = #Predicate<Category> {
            $0.typeRawValue == rawValue
        }
        
        guard let fetchedCategories = await fetch(withPredicate: predicate, sort: [SortDescriptor(\.placement)]) else {
            errorHandler?(FetchErrors.unableToFetchCategories)
            return
        }
        
        withAnimation(.snappy) {
            availableCategories = fetchedCategories
        }
    }
    
    @MainActor
    private func fetchTags(errorHandler: (@Sendable (Error) -> Void)? = nil) async {
        guard let fetchedTags: [Tag] = await fetch() else {
            errorHandler?(FetchErrors.unableToFetchTags)
            return
        }
        
        withAnimation(.snappy) {
            availableTags = fetchedTags
        }
    }
    
    @MainActor
    private func fetchBalanceAccounts(errorHandler: (@Sendable (Error) -> Void)? = nil) async {
        guard let fetchedBalanceAccounts: [BalanceAccount] = await fetch() else {
            errorHandler?(FetchErrors.unableToFetchBalanceAccounts)
            return
        }
        
        withAnimation(.snappy) {
            availableBalanceAccounts = fetchedBalanceAccounts
        }
    }
    
    private func fetch<T>(withPredicate: Predicate<T>? = nil, sort: [SortDescriptor<T>] = []) async -> [T]? where T: PersistentModel, T: Sendable {
        let descriptor = FetchDescriptor<T>(
            predicate: withPredicate,
            sortBy: sort
        )
        
        do {
            var fetchedItems: [T] = []
            switch dataThread {
            case .main:
                fetchedItems = try await dataManager.fetch(descriptor)
            case .global:
                fetchedItems = try await dataManager.fetchFromBackground(descriptor)
            }
            //to show the last added data at the first places
            if sort.isEmpty {
                fetchedItems.reverse()
            }
            return fetchedItems
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    private func setTransactionPropertiesToViewModel(transaction: Transaction) {
        if let trType = transaction.type, trType != transactionsTypeSelected {
            transactionsTypeSelected = trType
        }
        comment = transaction.comment
        value = transaction.value
        valueString = String(value).replacing(".", with: ",")
        date = transaction.date
        balanceAccount = transaction.balanceAccount ?? .emptyBalanceAccount
        category = transaction.category
        tags = transaction.tags
    }
    
    private func setDateArray() {
        let calendar = Calendar.current
        var array: [Date] = []
        if calendar.startOfDay(for: date) == calendar.startOfDay(for: .now) {
            guard let prepreviousDay = calendar.date(byAdding: .day, value: -2, to: date),
                  let previousDay = calendar.date(byAdding: .day, value: -1, to: date) else {
                return
            }
            
            array = [prepreviousDay, previousDay, date]
        } else if calendar.startOfDay(for: date) == calendar.startOfDay(for:availableDateRange.lowerBound) {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: date),
                  let nextnextDay = calendar.date(byAdding: .day, value: 2, to: date) else {
                return
            }
            
            array = [date, nextDay, nextnextDay]
        } else {
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: date),
                  let nextDay = calendar.date(byAdding: .day, value: 1, to: date) else {
                return
            }
            
            array = [previousDay, date, nextDay]
        }
        
        withAnimation {
            threeDatesArray = array
        }
    }
    
    private func setSelectedTagsFirstInArray(withDelay: DispatchTime) {
        guard !tags.isEmpty else { return }
        
        DispatchQueue.global().asyncAfter(deadline: withDelay) { [weak self] in
            guard let self else { return }
            let notSelectedTagsArray = self.availableTags.filter {
                !self.tags.contains($0)
            }
            
            guard !notSelectedTagsArray.isEmpty else { return }
            
            let firstSelectedAllTags = self.tags + notSelectedTagsArray
            
            DispatchQueue.main.async {
                withAnimation {
                    self.availableTags = firstSelectedAllTags
                }
            }
        }
    }
}

//MARK: Fixing Extension
extension AddingSpendIcomeViewModel {
    // This property is embed in extension as there a problem accures with another method while the property is in the class
    var searchedTags: [Tag] {
        guard !searchTagText.isEmpty else {
            return availableTags
        }
        return availableTags.filter {
            $0.name.lowercased().contains(searchTagText.lowercased())
        }
    }
    
    var isThereFullyIdenticalTag: Bool {
        searchedTags.map { $0.name.lowercased() }.contains(searchTagText.lowercased())
    }
}

//MARK: AddingCategoryViewModelProtocol extension
extension AddingSpendIcomeViewModel: AddingCategoryViewModelDelegate {
    func didUpdateCategory() {
        Task {
            await fetchCategories()
        }
        delegate?.categoryUpdated()
    }
}

extension AddingSpendIcomeViewModel: AddingBalanceAccountViewModelDelegate {
    func didUpdateBalanceAccount(_ balanceAccount: BalanceAccount) {
        Task {
            await fetchBalanceAccounts()
        }
    }
}
