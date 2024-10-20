//
//  AddingTransferViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 08.10.2024.
//

import Foundation
import SwiftData
import SwiftUI

protocol AddingTransferViewModelDelegate: AnyObject {
    func didAddTransferTransaction(_ transferTransaction: TransferTransaction)
    func didUpdateTransferTransaction(_ transferTransaction: TransferTransaction)
    func didDeleteTransferTransaction(_ transferTransaction: TransferTransaction)
}

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
    
    enum SaveTransferTransactionError: Error {
        case invalidValue
        case invalidFromBalanceAccount
        case invalidToBalanceAccount
        case fromAndToBalanceAccountsEqual
        case invalidCurrencyRate
        case saveDataError
        case unknown
        
        var saveErrorLocalizedDescription: LocalizedStringResource {
            switch self {
            case .invalidValue:
                return "Value cannot be zero, negative or empy"
            case .invalidFromBalanceAccount:
                return "Balance account to transfer from is not selected"
            case .invalidToBalanceAccount:
                return "Balance account to transfer to is not selected"
            case .fromAndToBalanceAccountsEqual:
                return "Balance accounts to transfer from and to cannot be equal"
            case .invalidCurrencyRate:
                return "Currency rate cannot be zero, negative or empy"
            case .saveDataError:
                return "Some save error occured"
            case .unknown:
                return "Unknown error occured, please try again"
            }
        }
    }
    
    //MARK: - Properties
    private let dataManager: any DataManagerProtocol
    private var dateArrayWorkItem: DispatchWorkItem?
    let action: ActionWithTransferTransaction
    let availableDateRange = FTAppAssets.availableDateRange
    weak var delegate: (any AddingTransferViewModelDelegate)?
    
    //MARK: Published properties
    @MainActor @Published var valueFrom: Float = 0
    @MainActor @Published var valueFromString: String = ""
    @MainActor @Published var date: Date = .now {
        didSet {
            dateArrayWorkItem?.cancel()
            dateArrayWorkItem = DispatchWorkItem { [weak self] in
                Task { @MainActor in
                    self?.setDateArray()
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: dateArrayWorkItem!)
        }
    }
    @MainActor @Published var fromBalanceAccount: BalanceAccount? {
        didSet {
            if let fromBalanceAccount, fromBalanceAccount.id != oldValue?.id, fromBalanceAccount.id == toBalanceAccount?.id {
                toBalanceAccount = nil
            }
        }
    }
    @MainActor @Published var toBalanceAccount: BalanceAccount? {
        didSet {
            if let toBalanceAccount, toBalanceAccount.id != oldValue?.id, toBalanceAccount.id == fromBalanceAccount?.id {
                fromBalanceAccount = nil
            }
        }
    }
    @MainActor @Published var comment: String = ""
    
    @MainActor @Published var currencyRateString: String = "1"
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
    @MainActor @Published private(set) var threeDatesArray: [Date] = []
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol, action: ActionWithTransferTransaction) {
        self.dataManager = dataManager
        self.action = action
        initing()
    }
    
    //MARK: - Methods
    func saveTransferTransaction(resultHandler: @escaping @MainActor (Result<Void, SaveTransferTransactionError>) -> Void) {
        Task { @MainActor in
            var errorHappend: Bool = false
            let localErrorHandler: (SaveTransferTransactionError) -> Void = { error in
                errorHappend = true
                resultHandler(.failure(error))
            }
            
            switch action {
            case .add:
                addTransferTransaction(errorHandler: localErrorHandler)
            case .update:
                updateTransferTransaction(errorHandler: localErrorHandler)
            }
            
            guard !errorHappend else { return }
            resultHandler(.success(()))
        }
    }
    
    @MainActor
    func switchBalanceAccounts() {
        let bufferFrom = fromBalanceAccount
        fromBalanceAccount = toBalanceAccount
        toBalanceAccount = bufferFrom
    }
    
    //MARK: Private methods
    private func initing() {
        Task { @MainActor in
            setActionData()
            setDateArray()
            await fetchBalanceAccounts()
        }
    }
    
    @MainActor
    private func updateTransferTransaction(errorHandler: (SaveTransferTransactionError) -> Void) {
        guard case .update(let transferTransaction) = action else {
            print("AddingTransferViewModel, updateTransferTransaction: Action is not update")
            return
        }
        
        do {
            try checkValidity()
        } catch let error as SaveTransferTransactionError {
            errorHandler(error)
            return
        } catch {
            errorHandler(.unknown)
            return
        }
        
        transferTransaction.valueFrom = valueFrom
        transferTransaction.valueTo = valueToConverted
        transferTransaction.date = date
        transferTransaction.comment = comment
        transferTransaction.setFromBalanceAccount(fromBalanceAccount!)
        transferTransaction.setToBalanceAccount(toBalanceAccount!)
        
        do {
            try dataManager.save()
            delegate?.didUpdateTransferTransaction(transferTransaction)
        } catch {
            errorHandler(.saveDataError)
        }
    }
    
    @MainActor
    private func addTransferTransaction(errorHandler: (SaveTransferTransactionError) -> Void) {
        do {
            try checkValidity()
        } catch let error as SaveTransferTransactionError {
            errorHandler(error)
            return
        } catch {
            errorHandler(.unknown)
            return
        }
        
        // because checkValidity() checks properties, we can safely force unwrap values
        let transferTransaction = TransferTransaction(
            valueFrom: valueFrom,
            valueTo: valueToConverted,
            date: date,
            comment: comment,
            fromBalanceAccount: fromBalanceAccount!,
            toBalanceAccount: toBalanceAccount!
        )
        
        dataManager.insert(transferTransaction)
        delegate?.didAddTransferTransaction(transferTransaction)
    }
    
    @MainActor
    private func checkValidity() throws {
        guard valueFrom > 0 else {
            throw SaveTransferTransactionError.invalidValue
        }
        
        guard currencyRateValue > 0 else {
            throw SaveTransferTransactionError.invalidCurrencyRate
        }
        
        guard fromBalanceAccount != nil else {
            throw SaveTransferTransactionError.invalidFromBalanceAccount
        }
        
        guard toBalanceAccount != nil else {
            throw SaveTransferTransactionError.invalidToBalanceAccount
        }
        
        guard fromBalanceAccount != toBalanceAccount else {
            throw SaveTransferTransactionError.fromAndToBalanceAccountsEqual
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
    
    @MainActor
    private func setDateArray() {
        let calendar = Calendar.current
        var array: [Date] = []
        if calendar.startOfDay(for: date) == calendar.startOfDay(for: .now) {
            guard let prepreviousDay = calendar.date(byAdding: .day, value: -2, to: date),
                  let previousDay = calendar.date(byAdding: .day, value: -1, to: date) else {
                return
            }
            
            array = [prepreviousDay, previousDay, date]
        } else if calendar.startOfDay(for: date) == calendar.startOfDay(for: availableDateRange.lowerBound) {
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
}
