//
//  AddingSpendIcomeViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 29.05.2024.
//

import Foundation
import SwiftData
import SwiftUI

protocol AddingSpendIcomeViewModelDelegate: AnyObject {
    func addedNewTransaction(_ transaction: Transaction)
    func updateTransaction(_ transaction: Transaction)
    func transactionsTypeReselected(to newType: TransactionsType)
    func categoryUpdated()
}

enum FetchErrors: Error {
    case unableToFetchCategories
    case unableToFetchTags
    case unableToFetchBalanceAccounts
}

final class AddingSpendIcomeViewModel: ObservableObject {
    enum SaveErrors: Error {
        case categoryIsNil
        case valueIsZero
        case contextSaveError
        
        var localizedDescription: String {
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
    weak var delegate: (any AddingSpendIcomeViewModelDelegate)?
    var action: ActionWithTransaction = .none {
        didSet {
            switch action {
            case .add(let providedDate):
                date = providedDate
                //TODO: set default values to balanceAccount
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
    @Published var balanceAccount: BalanceAccount = .emptyBalanceAccount
    @Published var category: Category?
    @Published var tags: [Tag] = [] {
        didSet {
            setSelectedTagsFirstInArray(withDelay: .now() + 1.5)
        }
    }
    
    //MARK: Initializer
    init(dataManager: some DataManagerProtocol, transactionsTypeSelected: TransactionsType) {
        self.dataManager = dataManager
        self._transactionsTypeSelected = Published(wrappedValue: transactionsTypeSelected)
        fetchAllData()
    }
    
    //MARK: Methods
    /// Updates or saves new transaction
    func saveTransaction(completionHanler: ((SaveErrors?) -> Void)? = nil) {
        // Field checking
        guard value > 0 else {
            completionHanler?(.valueIsZero)
            return
        }
        
        guard let category else {
            completionHanler?(.categoryIsNil)
            return
        }
        
        // Saving
        if let transactionToUpdate {
            transactionToUpdate.type = transactionsTypeSelected
            transactionToUpdate.value = value
            transactionToUpdate.category = category
            transactionToUpdate.balanceAccount = balanceAccount
            transactionToUpdate.date = date
            transactionToUpdate.tags = tags
            transactionToUpdate.comment = comment
            Task {
                do {
                    try await dataManager.save()
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
                await dataManager.insert(newTransaction)
            }
        }
        
        completionHanler?(nil)
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
        
        let newTag: Tag
        if let color {
            newTag = Tag(name: name, color: color)
        } else {
            newTag = Tag(name: name)
        }
        if andSelect {
            addRemoveTag(newTag)
        }
        Task {
            await dataManager.insert(newTag)
            await fetchTags()
        }
    }
    
    func deleteUpdatedTransaction(completionHandler: (() -> Void)?) {
        guard let transactionToUpdate else { return }
        Task {
            await dataManager.deleteTransaction(transactionToUpdate)
            completionHandler?()
        }
    }
    
    func getAddingCategoryView(action: ActionWithCategory) -> some View {
        let viewModel = AddingCategoryViewModel(dataManager: dataManager, transactionType: transactionsTypeSelected, action: action)
        viewModel.delegate = self
        
        return AddingCategoryView(viewModel: viewModel)
    }
    
    func getAddingBalanceAccountView() -> some View {
        let viewModel = AddingBalanceAccountViewModel(dataManager: dataManager, action: .add)
        viewModel.delegate = self
        
        return AddingBalanceAccauntView(viewModel: viewModel)
    }
    
    private func fetchAllData(errorHandler: ((Error) -> Void)? = nil) {
        Task {
            await fetchCategories(errorHandler: errorHandler)
            await fetchTags(errorHandler: errorHandler)
            await fetchBalanceAccounts(errorHandler: errorHandler)
        }
    }
    
    @MainActor
    private func fetchCategories(errorHandler: ((Error) -> Void)? = nil) async {
        // It is needed to prevent Predicate type convertion error (cannot reference an object property inside of a Predicate)
        let rawValue = transactionsTypeSelected.rawValue
        
        let predicate = #Predicate<Category> {
            $0.typeRawValue == rawValue
        }
        
        guard let fetchedCategories = await fetch(withPredicate: predicate) else {
            errorHandler?(FetchErrors.unableToFetchCategories)
            return
        }
        
        withAnimation(.snappy) {
            availableCategories = fetchedCategories
        }
    }
    
    @MainActor
    private func fetchTags(errorHandler: ((Error) -> Void)? = nil) async {
        guard let fetchedTags: [Tag] = await fetch() else {
            errorHandler?(FetchErrors.unableToFetchTags)
            return
        }
        
        withAnimation(.snappy) {
            availableTags = fetchedTags
        }
    }
    
    @MainActor
    private func fetchBalanceAccounts(errorHandler: ((Error) -> Void)? = nil) async {
        guard let fetchedBalanceAccounts: [BalanceAccount] = await fetch(sortWithString: \.name) else {
            errorHandler?(FetchErrors.unableToFetchBalanceAccounts)
            return
        }
        
        withAnimation(.snappy) {
            availableBalanceAccounts = fetchedBalanceAccounts
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
    
    private func setTransactionPropertiesToViewModel(transaction: Transaction) {
        if let trType = transaction.type, trType != transactionsTypeSelected {
            transactionsTypeSelected = trType
        }
        comment = transaction.comment
        value = transaction.value
        valueString = String(value).replacing(".", with: ",")
        date = transaction.date
        balanceAccount = transaction.balanceAccount
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
    func didUpdateBalanceAccount() {
        Task {
            await fetchBalanceAccounts()
        }
    }
}
