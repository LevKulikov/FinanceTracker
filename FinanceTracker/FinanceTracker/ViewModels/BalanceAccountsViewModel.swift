//
//  BalanceAccountsViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 20.06.2024.
//

import Foundation
import SwiftData
import SwiftUI

protocol BalanceAccountsViewModelDelegate: AnyObject {
    func didUpdatedBalanceAccountsList()
    func didDeleteBalanceAccount()
}

final class BalanceAccountsViewModel: ObservableObject {
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
        Task { @MainActor in
            dataManager.deleteBalanceAccount(balanceAccount)
            delegate?.didDeleteBalanceAccount()
            await fetchBalanceAccounts()
        }
    }
    
    func deleteBalanceAccountWithTransactions(_ balanceAccount: BalanceAccount) {
        Task { @MainActor in
            dataManager.deleteBalanceAccountWithTransactions(balanceAccount)
            delegate?.didDeleteBalanceAccount()
            await fetchBalanceAccounts()
        }
    }
    
    func getAddingBalanceAccountView(for action: ActionWithBalanceAccaunt) -> some View {
        return FTFactory.shared.createAddingBalanceAccauntView(dataManager: dataManager, action: action, delegate: self)
    }
    
    //TODO: Implement balance account deletion
    func delete(balanceAccount: BalanceAccount?, competionHandler: (() -> Void)? = nil) {
        Task { @MainActor in
            competionHandler?()
        }
    }
    
    //MARK: Private methods
    @MainActor
    private func fetchBalanceAccounts(errorHandler: ((Error) -> Void)? = nil) async {
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
    func didUpdateBalanceAccount() {
        fetchData()
        delegate?.didUpdatedBalanceAccountsList()
    }
}
