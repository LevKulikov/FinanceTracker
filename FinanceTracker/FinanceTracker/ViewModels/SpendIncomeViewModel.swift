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

final class SpendIncomeViewModel: ObservableObject {
    enum DateSettingDestination {
        case back
        case forward
    }
    
    //MARK: - Properties
    private let dataManager: any DataManagerProtocol
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
    
    @Published var transactionsTypeSelected: TransactionsType = .spending {
        didSet {
            fetchTransactions()
        }
    }
    @Published private(set) var transactions: [Transaction] = []
    @Published var dateSelected: Date = .now
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
        fetchTransactions()
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
        let viewModel = AddingSpendIcomeViewModel(dataManager: dataManager, transactionsTypeSelected: transactionsTypeSelected)
        viewModel.delegate = self
        
        return AddingSpendIcomeView(action: forAction, namespace: namespace, viewModel: viewModel)
    }
    
    func fetchTransactions() {
        Task {
            await fetchTransactions()
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
}

//MARK: Extension for AddingSpendIcomeViewModelDelegate
extension SpendIncomeViewModel: AddingSpendIcomeViewModelDelegate {
    func addedNewTransaction(_ transaction: Transaction) {}
    
    func updateTransaction(_ transaction: Transaction) {}
    
    func transactionsTypeReselected(to newType: TransactionsType) {
        transactionsTypeSelected = newType
    }
    
    func categoryUpdated() {
        fetchTransactions()
    }
}
