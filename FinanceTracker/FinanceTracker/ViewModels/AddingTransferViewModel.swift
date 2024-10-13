//
//  AddingTransferViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 08.10.2024.
//

import Foundation
import SwiftData
import SwiftUI

enum ActionWithTransferTransaction: Equatable, Hashable {
    case add(template: TransferTransaction? = nil)
    case update(TransferTransaction)
}

final class AddingTransferViewModel: ObservableObject, @unchecked Sendable {
    /// Way how to use entered currency rate
    enum CurrencyRateWay: Equatable, CaseIterable {
        /// From RUB balance account to USD balance account, USD / RUB = 100 for example, so 100 000 RUB / 100 = 1 000 USD
        case divide
        /// From EUR balance account to USD balance account, EUR / USD = 1.1 for example, so 1 000 EUR x 1.1 = 1 100 USD
        case multiply
    }
    
    //MARK: - Properties
    private let dataManager: any DataManagerProtocol
    private let action: ActionWithTransferTransaction
    
    //MARK: Published properties
    @MainActor var valueFrom: Float = 0
    @MainActor @Published var valueFromString: String = ""
    @MainActor @Published var date: Date = .now
    @MainActor @Published var fromBalanceAccount: BalanceAccount?
    @MainActor @Published var toBalanceAccount: BalanceAccount?
    @MainActor @Published var comment: String = ""
    
    @MainActor @Published var currencyRateValue: Float = 1
    @MainActor @Published var currencyRateWay: CurrencyRateWay = .divide
    @MainActor var valueToConverted: Float {
        switch currencyRateWay {
        case .divide:
            guard currencyRateValue != 0 else { return 0 }
            return valueFrom / currencyRateValue
        case .multiply:
            return valueFrom * currencyRateValue
        }
    }
    
    @MainActor @Published private(set) var isFetchingBalanceAccounts: Bool = false
    @MainActor @Published private(set) var balanceAccounts: [BalanceAccount] = []
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol, action: ActionWithTransferTransaction) {
        self.dataManager = dataManager
        self.action = action
        initing()
    }
    
    //MARK: - Methods
    
    //MARK: Private methods
    private func initing() {
        Task { @MainActor in
            setActionData()
            await fetchBalanceAccounts()
        }
    }
    
    @MainActor
    private func fetchBalanceAccounts() async {
        guard !isFetchingBalanceAccounts else { return }
        isFetchingBalanceAccounts = true
        
        defer {
            isFetchingBalanceAccounts = false
        }
        
        let descriptor = FetchDescriptor<BalanceAccount>()
        do {
            let balanceAccounts = try dataManager.fetch(descriptor)
            self.balanceAccounts = balanceAccounts
        } catch {
            print(error)
        }
    }
    
    @MainActor
    private func setActionData() {
        switch action {
        case .add(let template):
            if let template {
                fromBalanceAccount = template.fromBalanceAccount
                toBalanceAccount = template.fromBalanceAccount?.id != template.toBalanceAccount?.id ? template.toBalanceAccount : nil
                if fromBalanceAccount?.currency != toBalanceAccount?.currency {
                    // currencyRateWay is divide by default
                    currencyRateValue = template.valueFrom / template.valueTo
                }
                date = template.date
                comment = template.comment
                valueFrom = template.valueFrom
                valueFromString = String(valueFrom)
            }
        case .update(let transaction):
            valueFrom = transaction.valueFrom
            valueFromString = String(transaction.valueFrom)
            date = transaction.date
            fromBalanceAccount = transaction.fromBalanceAccount
            toBalanceAccount = transaction.toBalanceAccount
            comment = transaction.comment
            
            if fromBalanceAccount?.currency != toBalanceAccount?.currency {
                // currencyRateWay is divide by default
                currencyRateValue = transaction.valueFrom / transaction.valueTo
            }
        }
    }
}
