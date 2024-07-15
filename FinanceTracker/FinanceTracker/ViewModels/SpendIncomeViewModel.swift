//
//  SpendIncomeViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 25.05.2024.
//

import Foundation
import SwiftUI
import SwiftData
import Algorithms
import Combine

protocol SpendIncomeViewModelDelegate: AnyObject {
    func didSelectAction(_ action: ActionWithTransaction)
    func didUpdateTransactionList()
}

enum ActionWithTransaction: Equatable {
    case none
    case add(Date)
    case update(Transaction)
}

enum DateSettingDestination: Equatable {
    case back
    case forward
}

final class SpendIncomeViewModel: ObservableObject {
    //MARK: - Properties
    //MARK: Private props
    private let dataManager: any DataManagerProtocol
    private var transactions: [Transaction] = []
    private let calendar = Calendar.current
    private var cancelables = Set<AnyCancellable>()
    
    //MARK: Internal props
    weak var delegate: (any SpendIncomeViewModelDelegate)?
    
    var availableDateRange: ClosedRange<Date> {
        FTAppAssets.availableDateRange
    }
    var movingBackwardDateAvailable: Bool {
        guard let backDate = calendar.date(byAdding: .day, value: -1, to: dateSelected) else {
            return false
        }
        return availableDateRange.contains(backDate)
    }
    var movingForwardDateAvailable: Bool {
        guard let forwardDate = calendar.date(byAdding: .day, value: 1, to: dateSelected) else {
            return false
        }
        return availableDateRange.contains(forwardDate)
    }
    
    //MARK: Published props
    @Published private(set) var transactionsValueSum: Float = 0
    @Published private(set) var filteredGroupedTranactions: [[Transaction]] = []
    @Published var tapEnabled = true
    @Published var actionSelected: ActionWithTransaction = .none {
        didSet {
            didSelectAction(action: actionSelected)
            if actionSelected == .none {
                enableTapsWithDeadline()
            }
        }
    }
    @Published var transactionsTypeSelected: TransactionsType = .spending {
        didSet {
            filterGroupSortTransactions(animated: true)
        }
    }
    @Published private(set) var availableBalanceAccounts: [BalanceAccount] = []
    @Published var dateSelected: Date = .now {
        didSet {
            Task {
                await fetchTransactions()
                filterGroupSortTransactions()
            }
        }
    }
    @Published var balanceAccountToFilter: BalanceAccount = .emptyBalanceAccount {
        didSet {
            filterGroupSortTransactions()
        }
    }
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
        fetchAllData { [weak self] in
            DispatchQueue.main.async {
                self?.balanceAccountToFilter = self?.dataManager.getDefaultBalanceAccount() ?? .emptyBalanceAccount
            }
        }
    }
    
    //MARK: - Methods
    func save(errorHandler: ((Error) -> Void)? = nil) {
        Task {
            do {
                try await dataManager.save()
                await fetchTransactions(errorHandler: errorHandler)
            } catch {
                errorHandler?(error)
            }
        }
    }
    
    func delete(_ transaction: Transaction, errorHandler: ((Error) -> Void)? = nil) {
        Task {
            await dataManager.deleteTransaction(transaction)
            await fetchTransactions(errorHandler: errorHandler)
        }
    }
    
    func insert(_ transaction: Transaction, errorHandler: ((Error) -> Void)? = nil) {
        Task {
            await dataManager.insert(transaction)
            await fetchTransactions(errorHandler: errorHandler)
        }
    }
    
    func setDate(destination: DateSettingDestination, withAnimation animated: Bool = true) {
        guard let newDate = calendar.date(byAdding: .day, value: destination == .back ? -1 : 1, to: dateSelected),
              availableDateRange.contains(newDate) else { return }
        if animated {
            withAnimation(.snappy(duration: 0.3)) {
                dateSelected = newDate
            }
        } else {
            dateSelected = newDate
        }
    }
    
    func getAddUpdateView(forAction: Binding<ActionWithTransaction>, namespace: Namespace.ID) -> some View {        
        return FTFactory.shared.createAddingSpendIcomeView(
            dataManager: dataManager,
            threadToUse: .main,
            transactionType: transactionsTypeSelected,
            balanceAccount: balanceAccountToFilter,
            forAction: forAction,
            namespace: namespace,
            delegate: self
        )
    }
    
    func didSelectAction(action: ActionWithTransaction) {
        delegate?.didSelectAction(action)
    }
    
    //MARK: Private props
    private func addButtonPressedFromTabBar() {
        guard tapEnabled else { return }
        tapEnabled = false
        withAnimation(.snappy(duration: 0.5)) {
            actionSelected = .add(dateSelected)
        }
    }
    
    private func enableTapsWithDeadline() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.tapEnabled = true
        }
    }
    
    /// Groups, filters and sorts fetshed transactions array and sets new array to published array of transactions (filteredGroupedTranactions) with default animation
    /// - Parameters:
    ///   - date: provide value to filter by date, if nil the method filters by selected from UI date
    ///   - balanceAccount: provide value to filter by balance account, if nil the method filters by selected from UI balance acount
    private func filterGroupSortTransactions(type: TransactionsType? = nil, balanceAccount: BalanceAccount? = nil, animated: Bool = false) {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self else { return }
            
            let changedTransactions = self.transactions
                .filter {
                    $0.type == (type ?? self.transactionsTypeSelected)
                }
                .filter {
                    $0.balanceAccount == balanceAccount ?? self.balanceAccountToFilter
                }
                .grouped { $0.category }
                .map { $0.value }
                .sorted {
                    ($0.first!.category?.name ?? "Err") < ($1.first!.category?.name ?? "Err")
                }
            
            let sumValue = changedTransactions.flatMap{$0}.map{$0.value}.reduce(0, +)
            
            DispatchQueue.main.async {
                if animated {
                    withAnimation{
                        self.filteredGroupedTranactions = changedTransactions
                        self.transactionsValueSum = sumValue
                    }
                } else {
                    self.filteredGroupedTranactions = changedTransactions
                    self.transactionsValueSum = sumValue
                }
            }
        }
    }
    
    private func fetchAllData(completionHandler: (()->Void)? = nil) {
        Task {
            await fetchTransactions()
            await fetchBalanceAccounts()
            completionHandler?()
        }
    }
    
    @MainActor
    private func fetchTransactions(errorHandler: ((Error) -> Void)? = nil) async {
        let startOfSelectedDate = calendar.startOfDay(for: dateSelected)
        let endOfSelectedDate = dateSelected.endOfDay() ?? dateSelected
        
        let predicate = #Predicate<Transaction> {
            (startOfSelectedDate...endOfSelectedDate).contains($0.date)
        }
        
        var descriptor = FetchDescriptor<Transaction>(
            predicate: predicate,
            sortBy: [SortDescriptor<Transaction>(\.date, order: .reverse)]
        )
        descriptor.relationshipKeyPathsForPrefetching = [\.category, \.balanceAccount]
        
        do {
            let fetchedTranses = try dataManager.fetch(descriptor)
            transactions = fetchedTranses
        } catch {
            errorHandler?(error)
        }
    }
    
    @MainActor
    private func fetchBalanceAccounts(errorHandler: ((Error) -> Void)? = nil) {
        let descriptor = FetchDescriptor<BalanceAccount>()
        
        do {
            let fetchedBAs = try dataManager.fetch(descriptor)
            availableBalanceAccounts = fetchedBAs
        } catch {
            errorHandler?(error)
        }
    }
}

//MARK: Extension for AddingSpendIcomeViewModelDelegate
extension SpendIncomeViewModel: AddingSpendIcomeViewModelDelegate {
    func addedNewTransaction(_ transaction: Transaction) {
        delegate?.didUpdateTransactionList()
        fetchAllData { [weak self] in
            self?.filterGroupSortTransactions()
        }
    }
    
    func updateTransaction(_ transaction: Transaction) {
        delegate?.didUpdateTransactionList()
        fetchAllData { [weak self] in
            self?.filterGroupSortTransactions()
        }
        enableTapsWithDeadline()
    }
    
    func deletedTransaction(_ transaction: Transaction) {
        delegate?.didUpdateTransactionList()
        fetchAllData { [weak self] in
            self?.filterGroupSortTransactions()
        }
        enableTapsWithDeadline()
    }
    
    func transactionsTypeReselected(to newType: TransactionsType) {
        transactionsTypeSelected = newType
    }
    
    func categoryUpdated() {
        delegate?.didUpdateTransactionList()
        fetchAllData { [weak self] in
            self?.filterGroupSortTransactions()
        }
    }
}

//MARK: Extension for CustomTabViewModelDelegate
extension SpendIncomeViewModel: CustomTabViewModelDelegate {
    var id: String {
        "SpendIncomeViewModel"
    }
    
    func addButtonPressed() {
        addButtonPressedFromTabBar()
    }
    
    func didUpdateData(for dataType: SettingsSectionAndDataType, from tabView: TabViewType) {
        guard tabView != .spendIncomeView else { return }
        
        switch dataType {
        case .balanceAccounts:
            Task { @MainActor in
                fetchBalanceAccounts()
                if tabView == .welcomeView {
                    balanceAccountToFilter = dataManager.getDefaultBalanceAccount() ?? .emptyBalanceAccount
                }
            }
        case .categories:
            Task {
                await fetchTransactions()
                filterGroupSortTransactions()
            }
        case .data:
            fetchAllData { [weak self] in
                self?.filterGroupSortTransactions()
                DispatchQueue.main.async {
                    self?.balanceAccountToFilter = self?.dataManager.getDefaultBalanceAccount() ?? .emptyBalanceAccount
                }
            }
        default:
            break
        }
    }
}

//MARK: - Sink extension
extension SpendIncomeViewModel {
    private func sinkOnPublishers() {
        sinkOnDate()
        sinkOnAction()
        sinkOnBalanceAccount()
        sinkOnTransactionType()
    }
    
    private func sinkOnTransactionType() {
        $transactionsTypeSelected
            .sink { [weak self] newTransactionType in
                self?.fetchAllData {
                    self?.filterGroupSortTransactions()
                }
            }
            .store(in: &cancelables)
    }
    
    private func sinkOnAction() {
        $actionSelected
            .sink { [weak self] newAction in
                self?.didSelectAction(action: newAction)
                if case .none = newAction {
                    self?.fetchAllData {
                        self?.filterGroupSortTransactions()
                    }
                    self?.enableTapsWithDeadline()
                }
            }
            .store(in: &cancelables)
    }
    
    private func sinkOnDate() {
        $dateSelected
            .sink { [weak self] newDate in
                self?.filterGroupSortTransactions()
            }
            .store(in: &cancelables)
    }
    
    private func sinkOnBalanceAccount() {
        $balanceAccountToFilter
            .sink { [weak self] newBalanceAccount in
                self?.filterGroupSortTransactions()
            }
            .store(in: &cancelables)
    }
}
