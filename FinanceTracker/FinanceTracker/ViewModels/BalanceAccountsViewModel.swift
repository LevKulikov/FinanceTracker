//
//  BalanceAccountsViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 20.06.2024.
//

import Foundation

final class BalanceAccountsViewModel: ObservableObject {
    //MARK: - Properties
    private let dataManager: any DataManagerProtocol
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
    }
    
    //MARK: - Methods
    
}
