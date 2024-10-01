//
//  TransfersViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 01.10.2024.
//

import Foundation
import SwiftData
import SwiftUI

final class TransfersViewModel: @unchecked Sendable, ObservableObject {
    //MARK: - Properties
    private let dataManager: any DataManagerProtocol
    /// The maximum number of transfers to be fetched per one fetch request
    private let maxFetchTransfersCount = 50
    private var currentFetchOffset: Int = 0
    
    
    //MARK: Published properties
    @MainActor @Published private(set) var transfers: [TransferTransaction] = []
    @MainActor @Published private(set) var isLoading: Bool = false
    @MainActor @Published private(set) var allTransfersAreFetched = false
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
    }
    
    //MARK: - Methods
    func loadData(errorHandler: (@MainActor @Sendable (Error) -> Void)? = nil) {
        Task {
            let localErrorHandler: @Sendable (Error) -> Void = { error in
                Task { @MainActor in
                    errorHandler?(error)
                }
            }
            await fetchTransfers(errorHandler: localErrorHandler)
        }
    }
    
    //MARK: Private methods
    private func fetchTransfers(errorHandler: (@Sendable (Error) -> Void)? = nil) async {
        guard await !allTransfersAreFetched, await !isLoading else { return }
        
        await MainActor.run {
            isLoading = true
        }
        
        var descriptor = FetchDescriptor<TransferTransaction>(
            sortBy: [.init(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = maxFetchTransfersCount
        descriptor.fetchOffset = currentFetchOffset
        
        do {
            let result = try await dataManager.fetch(descriptor)
            await MainActor.run {
                if !result.isEmpty {
                    transfers.append(contentsOf: result)
                    currentFetchOffset += maxFetchTransfersCount
                } else {
                    allTransfersAreFetched = true
                }
                
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                allTransfersAreFetched = true
            }
            errorHandler?(error)
        }
    }
}
