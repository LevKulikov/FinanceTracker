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

protocol SpendIncomeViewModelDelegate: AnyObject {
    func didSelectAction(_ action: ActionWithTransaction)
}

final class SpendIncomeViewModel: ObservableObject {
    enum DateSettingDestination {
        case back
        case forward
    }
    
    //MARK: - Properties
    private let dataManager: any DataManagerProtocol
    weak var delegate: (any SpendIncomeViewModelDelegate)?
    var addButtonAction: (() -> Void)?
    let calendar = Calendar.current
    var transactionsValueSum: Float {
        filteredGroupedTranactions.flatMap{$0}.map{$0.value}.reduce(0, +)
    }
    var availableDateRange: ClosedRange<Date> {
        Date(timeIntervalSince1970: 0)...Date.now
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
    var filteredGroupedTranactions: [[Transaction]] {
        let filteredGroupedByCategory = transactions
            .filter {
                calendar.isDate($0.date, equalTo: dateSelected, toGranularity: .day)
            }
            .filter {
                $0.balanceAccount == balanceAccountToFilter
            }
            .grouped { $0.category }
            .map { $0.value }
            .sorted {
                let result = calendar.compare($0.first!.date, to: $1.first!.date, toGranularity: .second)
                switch result {
                case .orderedDescending:
                    return true
                default:
                    return false
                }
            }
        return filteredGroupedByCategory
    }
    @Published var tapEnabled = true
    @Published var actionSelected: ActionWithTransaction = .none
    @Published var transactionsTypeSelected: TransactionsType = .spending {
        didSet {
            fetchAllData()
        }
    }
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var availableBalanceAccounts: [BalanceAccount] = []
    @Published var dateSelected: Date = .now
    @Published var balanceAccountToFilter: BalanceAccount = .emptyBalanceAccount
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
        fetchAllData()
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
        return FTFactory.createAddingSpendIcomeView(dataManager: dataManager, transactionType: transactionsTypeSelected, forAction: forAction, namespace: namespace, delegate: self)
    }
    
    func fetchAllData() {
        Task {
            await fetchTransactions()
            await fetchBalanceAccounts()
        }
    }
    
    func didSelectAction(action: ActionWithTransaction) {
        delegate?.didSelectAction(action)
    }
    
    private func addButtonPressedFromTabBar() {
        guard tapEnabled else { return }
        tapEnabled = false
        withAnimation(.snappy(duration: 0.5)) {
            actionSelected = .add(dateSelected)
        }
    }
    
    @MainActor
    private func fetchTransactions(errorHandler: ((Error) -> Void)? = nil) async {
        // It is needed to prevent Predicate type convertion error (cannot reference an object property inside of a Predicate)
        let rawValue = transactionsTypeSelected.rawValue
        
        let predicate = #Predicate<Transaction> {
            $0.typeRawValue == rawValue
        }
        
        let descriptor = FetchDescriptor<Transaction>(
            predicate: predicate,
            sortBy: [SortDescriptor<Transaction>(\.date, order: .reverse)]
        )
        do {
            let fetchedTranses = try dataManager.fetch(descriptor)
            
            withAnimation(.snappy) {
                transactions = fetchedTranses
            }
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
    func addedNewTransaction(_ transaction: Transaction) {}
    
    func updateTransaction(_ transaction: Transaction) {}
    
    func transactionsTypeReselected(to newType: TransactionsType) {
        transactionsTypeSelected = newType
    }
    
    func categoryUpdated() {
        fetchAllData()
    }
}

//MARK: Extension for CustomTabViewModelDelegate
extension SpendIncomeViewModel: CustomTabViewModelDelegate {
    func addButtonPressed() {
        addButtonPressedFromTabBar()
    }
}
