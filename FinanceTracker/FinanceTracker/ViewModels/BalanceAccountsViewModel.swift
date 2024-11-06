//
//  BalanceAccountsViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 20.06.2024.
//

import Foundation
import SwiftData
import SwiftUI

protocol BalanceAccountManipulationDelegate: AnyObject {
    func didAddBalanceAccount(_ balanceAccount: BalanceAccount, from tabView: TabViewType)
    func didUpdateBalanceAccount(_ balanceAccount: BalanceAccount, from tabView: TabViewType)
    func didDeleteBalanceAccount(_ balanceAccount: BalanceAccount, from tabView: TabViewType)
}

protocol BalanceAccountsViewModelDelegate: Sendable, TransferTransactionManipulationDelegate, BalanceAccountManipulationDelegate {
    func didDeleteBalanceAccountWithTransactions(_ balanceAccount: BalanceAccount)
}

final class BalanceAccountsViewModel: ObservableObject, @unchecked Sendable {
    //MARK: - Properties
    weak var delegate: (any BalanceAccountsViewModelDelegate)?
    
    //MARK: Private props
    private let dataManager: any DataManagerProtocol
    
    //MARK: Published
    @Published private(set) var balanceAccounts: [BalanceAccount] = []
    @Published private(set) var defaultBalanceAccount: BalanceAccount?
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
        fetchData()
    }
    
    //MARK: - Methods
    func fetchData() {
        Task { @MainActor in
            await fetchBalanceAccounts()
            getDefaultBalanceAccount()
        }
    }
    
    func setDefaultBalanceAccount(_ balanceAccount: BalanceAccount) {
        dataManager.setDefaultBalanceAccount(balanceAccount)
        defaultBalanceAccount = balanceAccount
    }
    
    func deleteBalanceAccount(_ balanceAccount: BalanceAccount) {
        Task { @MainActor [dataManager, delegate] in
            dataManager.deleteBalanceAccount(balanceAccount)
            delegate?.didDeleteBalanceAccount(balanceAccount, from: .settingsView)
            await fetchBalanceAccounts()
        }
    }
    
    func checkIfDefaultBalanceAccountHasSameCurrency(with balanceAccount: BalanceAccount) -> Bool {
        return balanceAccount.currency == defaultBalanceAccount?.currency
    }
    
    func deleteBalanceAccountWithTransactions(_ balanceAccount: BalanceAccount) {
        Task { @MainActor [dataManager, delegate] in
            dataManager.deleteBalanceAccountWithTransactions(balanceAccount)
            delegate?.didDeleteBalanceAccountWithTransactions(balanceAccount)
            await fetchBalanceAccounts()
        }
    }
    
    @MainActor
    func getAddingBalanceAccountView(for action: ActionWithBalanceAccaunt) -> some View {
        return FTFactory.shared.createAddingBalanceAccauntView(dataManager: dataManager, action: action, delegate: self)
    }
    
    @MainActor
    func getTransfersView() -> some View {
        return FTFactory.shared.createTransfersView(dataManager: dataManager, delegate: self)
    }
    
    //MARK: Private methods
    @MainActor
    private func fetchBalanceAccounts(errorHandler: (@Sendable (Error) -> Void)? = nil) async {
        let descriptor = FetchDescriptor<BalanceAccount>(sortBy: [SortDescriptor(\.name)])
        
        do {
            let fetchedBalanceAccounts = try dataManager.fetch(descriptor)
            withAnimation(.snappy) {
                balanceAccounts = fetchedBalanceAccounts
            }
        } catch {
            errorHandler?(error)
        }
    }
    
    private func getDefaultBalanceAccount() {
        defaultBalanceAccount = dataManager.getDefaultBalanceAccount()
    }
}

//MARK: - Extensions
//MARK: Extension for AddingBalanceAccountViewModelDelegate
extension BalanceAccountsViewModel: AddingBalanceAccountViewModelDelegate {
    func didUpdateBalanceAccount(_ balanceAccount: BalanceAccount, from tabView: TabViewType) {
        fetchData()
        delegate?.didUpdateBalanceAccount(balanceAccount, from: tabView)
    }
    
    func didAddBalanceAccount(_ balanceAccount: BalanceAccount, from tabView: TabViewType) {
        fetchData()
        delegate?.didAddBalanceAccount(balanceAccount, from: tabView)
    }
    
    func didDeleteBalanceAccount(_ balanceAccount: BalanceAccount, from tabView: TabViewType) {
        fetchData()
        delegate?.didDeleteBalanceAccount(balanceAccount, from: tabView)
    }
}

//MARK: Extension for TransfersViewModelDelegate
extension BalanceAccountsViewModel: TransfersViewModelDelegate {
    func didAddTransferTransaction(_ transfer: TransferTransaction, from tabView: TabViewType) {
        delegate?.didAddTransferTransaction(transfer, from: .settingsView)
    }
    
    func didUpdateTransferTransaction(_ transfer: TransferTransaction, from tabView: TabViewType) {
        delegate?.didUpdateTransferTransaction(transfer, from: .settingsView)
    }
    
    func didDeleteTransferTransaction(_ transfer: TransferTransaction, from tabView: TabViewType) {
        delegate?.didDeleteTransferTransaction(transfer, from: .settingsView)
    }
}
