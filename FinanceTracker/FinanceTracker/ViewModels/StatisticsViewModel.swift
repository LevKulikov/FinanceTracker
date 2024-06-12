//
//  StatisticsViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 13.06.2024.
//

import Foundation
import SwiftUI
import SwiftData

final class StatisticsViewModel: ObservableObject {
    //MARK: - Properties
    private let dataManager: any DataManagerProtocol
    @Published var transactions: [Transaction] = []
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
        Task {
            await fetchTransactions()
        }
    }
    
    //MARK: - Methods
    @MainActor
    private func fetchTransactions() async {
        let descriptor = FetchDescriptor<Transaction>(
            predicate: nil,
            sortBy: [SortDescriptor<Transaction>(\.date, order: .reverse)]
        )
        do {
            let fetchedTranses = try dataManager.fetch(descriptor)
            transactions = fetchedTranses
        } catch {
            print("Unable to fetch transactions")
        }
    }
}
