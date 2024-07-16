//
//  TransactionListViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 16.07.2024.
//

import Foundation
import SwiftUI
import SwiftData

protocol TransactionListViewModelDelegate: AnyObject {
    func didUpdatedTransaction()
}

/// Struct is only for convenience of providing data
struct TransactionListUIData: Identifiable {
    let id = UUID().uuidString
    let transactions: [Transaction]
    let title: String
}

final class TransactionListViewModel: ObservableObject {
    //MARK: - Properties
    weak var delegate: (any TransactionListViewModelDelegate)?
    let title: String
    @Published private(set) var filteredTransactionGroups: [TransactionGroupedData] = []
    @Published private(set) var isGroupingAndSortingProceeds = false
    
    //MARK: Private properties
    private let dataManager: any DataManagerProtocol
    private var transactions: [Transaction]
    private let threadToUse: DataManager.DataThread
    private let calendar = Calendar.current
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol, transactions: [Transaction], title: String, threadToUse: DataManager.DataThread) {
        self.dataManager = dataManager
        self.transactions = transactions
        self.title = title
        self.threadToUse = threadToUse
        setTransactionGroups()
    }
    
    //MARK: - Methods
    func getAddingSpendIcomeView(for transaction: Transaction, namespace: Namespace.ID) -> some View {
        return FTFactory.shared.createAddingSpendIcomeView(dataManager: dataManager, threadToUse: threadToUse, transactionType: transaction.type ?? TransactionsType(rawValue: transaction.typeRawValue)!, balanceAccount: transaction.balanceAccount ?? .emptyBalanceAccount, forAction: .constant(.update(transaction)), namespace: namespace, delegate: self)
    }
    
    //MARK: Private methods
    private func setTransactionGroups() {
        DispatchQueue.main.async { [weak self] in
            self?.isGroupingAndSortingProceeds = true
        }
        
        DispatchQueue.global().async { [weak self] in
            let groupedTransactions = self?.transactions
                .grouped { trans in
                    let year = self?.calendar.component(.year, from: trans.date)
                    let month = self?.calendar.component(.month, from: trans.date)
                    let day = self?.calendar.component(.day, from: trans.date)
                    return DateComponents(year: year, month: month, day: day)
                }
                .map { dictTuple in
                    let date = self?.calendar.date(from: dictTuple.key) ?? .now
                    return TransactionGroupedData(date: date, transactions: dictTuple.value)
                }
                .sorted { $0.date > $1.date }
            
            guard let groupedTransactions else {
                DispatchQueue.main.async {
                    self?.isGroupingAndSortingProceeds = false
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.isGroupingAndSortingProceeds = false
                withAnimation {
                    self?.filteredTransactionGroups = groupedTransactions
                }
            }
        }
    }
}

//MARK: - Extensions
extension TransactionListViewModel: AddingSpendIcomeViewModelDelegate {
    func addedNewTransaction(_ transaction: Transaction) {
        delegate?.didUpdatedTransaction()
        setTransactionGroups()
    }
    
    func updateTransaction(_ transaction: Transaction) {
        delegate?.didUpdatedTransaction()
        setTransactionGroups()
    }
    
    func deletedTransaction(_ transaction: Transaction) {
        transactions.removeAll { transaction.id == $0.id }
        setTransactionGroups()
    }
    
    func transactionsTypeReselected(to newType: TransactionsType) { }
    
    func categoryUpdated() {}
}
