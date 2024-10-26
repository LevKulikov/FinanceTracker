//
//  AddingBalanceAccountViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 10.06.2024.
//

import Foundation
import SwiftUI
import SwiftData

protocol AddingBalanceAccountViewModelDelegate: AnyObject, Sendable {
    func didUpdateBalanceAccount(_ balanceAccount: BalanceAccount)
}

enum ActionWithBalanceAccaunt: Equatable, Hashable {
    case none
    case add
    case update(BalanceAccount)
}

final class AddingBalanceAccountViewModel: ObservableObject, @unchecked Sendable {
    //MARK: - Properties
    private let dataManager: any DataManagerProtocol
    private var balanceAccountToUpdate: BalanceAccount?
    private var transactionWithBalanceAccount: [Transaction] = []
    private var transfersWithBalanceAccount: [TransferTransaction] = []
    private var transactionsChanges: Float = 0
    weak var delegate: (any AddingBalanceAccountViewModelDelegate)?
    
    //MARK: Published props
    @Published private(set) var action: ActionWithBalanceAccaunt = .none
    @Published private(set) var availableBalanceAccounts: [BalanceAccount] = []
    @Published var balanceString: String = ""
    @Published private(set) var isFetching = false
    
    //MARK: Category props to set
    @Published var name: String = ""
    @Published var currency: String = "" {
        didSet {
            guard currencyPrecised != nil, currency != currencyPrecised?.code else { return }
            withAnimation {
                currencyPrecised = nil
            }
        }
    }
    /// Converted from balanceString to float from View
    var balance: Float = 0
    @Published var iconName: String = ""
    @Published var color: Color = .cyan
    @Published var currencyPrecised: Currency? {
        didSet {
            guard let currencyPrecised, currencyPrecised.id != oldValue?.id else { return }
            currency = currencyPrecised.code
        }
    }
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol, action: ActionWithBalanceAccaunt) {
        self.dataManager = dataManager
        self.action = action
        setData()
    }
    
    //MARK: - Methods
    func save(completionHandler: @MainActor @Sendable @escaping () -> Void) {
        switch action {
        case .none, .add:
            let newBalanceAccount = BalanceAccount(
                name: name,
                currency: currency,
                balance: balance,
                iconName: iconName,
                color: color
            )
            
            Task { @MainActor [dataManager, delegate] in
                dataManager.insert(newBalanceAccount)
                delegate?.didUpdateBalanceAccount(newBalanceAccount)
                completionHandler()
            }
        case .update:
            guard let balanceAccountToUpdate else {
                print("balanceAccountToUpdate is nil, though action is .update")
                return
            }
            
            let balanceToSet = !isFetching ? calculateNeededBalance() : balance
            
            balanceAccountToUpdate.name = name
            balanceAccountToUpdate.currency = currency
            balanceAccountToUpdate.balance = balanceToSet
            balanceAccountToUpdate.iconName = iconName
            balanceAccountToUpdate.color = color
            
            Task { @MainActor [dataManager, delegate] in
                do {
                    try dataManager.save()
                    delegate?.didUpdateBalanceAccount(balanceAccountToUpdate)
                    completionHandler()
                } catch {
                    print("Saving BalanceAccount error: \(error)")
                    return
                }
            }
        }
    }
    
    //MARK: Private methods
    private func setData() {
        switch action {
        case .none, .add:
            break
        case .update(let balanceAccount):
            balanceAccountToUpdate = balanceAccount
            name = balanceAccount.name
            currency = balanceAccount.currency
            balance = balanceAccount.balance
            iconName = balanceAccount.iconName
            color = balanceAccount.color
            
            Task { @MainActor in
                isFetching = true
                currencyPrecised = await FTAppAssets.getCurrency(for: currency)
            }
            
            Task.detached(priority: .high) {
                await self.setTransactionsChanges()
                
                await MainActor.run {
                    let totalBalance = self.balance + self.transactionsChanges
                    self.balanceString = FTFormatters.numberFormatterWithDecimals.string(for: totalBalance) ?? ""
                    self.isFetching = false
                }
            }
        }
    }
    
    private func setTransactionsChanges() async {
        await fetchTransactionsWithBalanceAccount(errorHandler: nil)
        await fetchTransferTransactionsWithBalanceAccount(errorHandler: nil)
        let changes = calulateTransactionsChanges()
        transactionsChanges = changes
    }
    
    private func fetchTransactionsWithBalanceAccount(errorHandler: (@Sendable (Error) -> Void)?) async {
        guard let balanceAccountToUpdate else { return }
        
        let copyBalanceAccountId = balanceAccountToUpdate.persistentModelID
        let predicate = #Predicate<Transaction> {
            $0.balanceAccount?.persistentModelID == copyBalanceAccountId
        }
        let descriptor = FetchDescriptor<Transaction>(predicate: predicate)
        
        do {
            let fetchedTransactions = try await dataManager.fetchFromBackground(descriptor)
            transactionWithBalanceAccount = fetchedTransactions
        } catch {
            errorHandler?(error)
        }
    }
    
    private func fetchTransferTransactionsWithBalanceAccount(errorHandler: (@Sendable (Error) -> Void)?) async {
        guard let balanceAccountToUpdate else { return }
        
        let copyBalanceAccountId = balanceAccountToUpdate.persistentModelID
        let predicate = #Predicate<TransferTransaction> {
            $0.fromBalanceAccount?.persistentModelID == copyBalanceAccountId || $0.toBalanceAccount?.persistentModelID == copyBalanceAccountId
        }
        let descriptor = FetchDescriptor<TransferTransaction>(predicate: predicate)
        
        do {
            let fetchedTransfers = try await dataManager.fetchFromBackground(descriptor)
            transfersWithBalanceAccount = fetchedTransfers
        } catch {
            errorHandler?(error)
        }
    }
    
    private func calulateTransactionsChanges() -> Float {
        let transactionsChanges = transactionWithBalanceAccount.map { trans in
            let value = trans.type == .income ? trans.value : -trans.value
            return value
        }.reduce(0, +)
        
        let transfersChanges = transfersWithBalanceAccount.map {
            switch balanceAccountToUpdate?.id {
            case $0.fromBalanceAccount?.id:
                return -$0.valueFrom
            case $0.toBalanceAccount?.id:
                return $0.valueTo
            default:
                return 0
            }
        }
        .reduce(0, +)
        
        return transactionsChanges + transfersChanges
    }
    
    private func calculateNeededBalance() -> Float {
        let valueToReturn = balance - transactionsChanges
        return valueToReturn
    }
}
