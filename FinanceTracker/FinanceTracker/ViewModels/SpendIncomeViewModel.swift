//
//  SpendIncomeViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 25.05.2024.
//

import Foundation
import SwiftUI
import SwiftData

final class SpendIncomeViewModel: ObservableObject {
    //MARK: - Properties
    private let dataManager: any DataManagerProtocol
    var currentDate: Date {
        Date.now
    }
    
    @Published var transactionsTypeSelected: TransactionsType = .spending {
        didSet {
            Task {
                await fetchTransactions()
            }
        }
    }
    @Published var transactions: [Transaction] = []
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
        Task {
            await fetchTransactions()
        }
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
            await dataManager.delete(transaction)
            await fetchTransactions(errorHandler: errorHandler)
        }
    }
    
    func insert(_ transaction: Transaction, errorHandler: ((Error) -> Void)? = nil) {
        Task {
            await dataManager.insert(transaction)
            await fetchTransactions(errorHandler: errorHandler)
        }
    }
    
    @ViewBuilder
    func getAddUpdateView(forAction: Binding<ActionWithTransaction>, namespace: Namespace.ID) -> some View {
        let viewModel = AddingSpendIcomeViewModel(dataManager: dataManager, transactionsTypeSelected: transactionsTypeSelected)
        AddingSpendIcomeView(action: forAction, namespace: namespace, viewModel: viewModel)
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
