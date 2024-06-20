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
}

final class BalanceAccountsViewModel: ObservableObject {
    //MARK: - Properties
    weak var delegate: (any BalanceAccountsViewModelDelegate)?
    
    //MARK: Private props
    private let dataManager: any DataManagerProtocol
    
    //MARK: Published
    @Published private(set) var balanceAccounts: [BalanceAccount] = []
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
        fetchData()
    }
    
    //MARK: - Methods
    func fetchData() {
        Task {
            await fetchBalanceAccounts()
        }
    }
    
    func getAddingBalanceAccountView(for action: ActionWithBalanceAccaunt) -> some View {
        return FTFactory.createAddingBalanceAccauntView(dataManager: dataManager, action: action, delegate: self)
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
}

//MARK: - Extensions
//MARK: Extension for AddingBalanceAccountViewModelDelegate
extension BalanceAccountsViewModel: AddingBalanceAccountViewModelDelegate {
    func didUpdateBalanceAccount() {
        fetchData()
        delegate?.didUpdatedBalanceAccountsList()
    }
}
