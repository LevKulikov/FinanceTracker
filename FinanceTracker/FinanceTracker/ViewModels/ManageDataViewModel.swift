//
//  ManageDataViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 25.06.2024.
//

import Foundation
import SwiftData

protocol ManageDataViewModelDelegate: AnyObject {
    func didDeleteAllTransactions()
    
    func didDeleteAllData()
}

final class ManageDataViewModel: ObservableObject, @unchecked Sendable {
    //MARK: - Properties
    weak var delegate: (any ManageDataViewModelDelegate)?
    
    //MARK: Published
    /// Used for JSON export, CSV export and etc
    @MainActor @Published var fileToExport: URL?
    @MainActor @Published private(set) var isDataFetchingForExport = false
    @MainActor @Published var dataExportError: Error?
    @MainActor @Published private(set) var isDataFetchingForCSVExport = false
    @MainActor @Published var csvExportError: Error?
    @MainActor @Published var csvStartDate: Date = .now.startOfMonth() ?? .now
    @MainActor @Published var csvEndDate: Date = .now
    
    //MARK: Private props
    private let dataManager: any DataManagerProtocol
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
    }
    
    //MARK: - Methods
    func deleteAllTransactions() {
        Task { [dataManager] in
            await dataManager.deleteAllTransactions()
        }
    }
    
    func deleteAllStoredData() {
        Task { [dataManager] in
            await dataManager.deleteAllStoredData()
        }
    }
    
    func getDataToExport() {
        Task(priority: .high) {
            await MainActor.run {
                isDataFetchingForExport = true
            }
            
            do {
                let dataContainer = try await dataManager.createDataContainer()
                let data = try JSONEncoder().encode(dataContainer)
                let fileURL = data.dataToFile(fileName: "FinanceTrackerData.json")
                
                await MainActor.run {
                    fileToExport = fileURL
                    isDataFetchingForExport = false
                }
            } catch {
                await MainActor.run {
                    isDataFetchingForExport = false
                    dataExportError = error
                }
                return
            }
        }
    }
    
    func getCSVToExport() {
        Task(priority: .high) {
            await MainActor.run {
                isDataFetchingForCSVExport = true
            }
            
            let startDate = await MainActor.run { return self.csvStartDate.startOfDay() }
            let endDate = await MainActor.run { return self.csvEndDate.endOfDay() ?? self.csvEndDate }
            let predicate = #Predicate<Transaction> {
                (startDate...endDate).contains($0.date)
            }
            
            let descriptor = FetchDescriptor<Transaction>(
                predicate: predicate,
                sortBy: [SortDescriptor<Transaction>(\.date, order: .reverse)]
            )
            
            do {
                let fetchedTransactions: [Transaction] = try await dataManager.fetchFromBackground(descriptor)
                let csvURL = try await createCSVFile(for: fetchedTransactions)
                
                await MainActor.run {
                    isDataFetchingForCSVExport = false
                    fileToExport = csvURL
                }
            } catch {
                await MainActor.run {
                    isDataFetchingForCSVExport = false
                    csvExportError = error
                }
            }
        }
    }
    
    //MARK: Private methods
    private func createCSVFile(for transactions: [Transaction]) async throws -> URL {
        var csvString = "Date,Type,Value,Currency,Category,Balance Account,Comment,Tags\n\n"
        for transaction in transactions {
            var tagsNames: String = ""
            for tag in transaction.tags {
                tagsNames += "\(tag.name);"
            }
            csvString.append("\(String(describing: transaction.date)),\(transaction.typeRawValue),\(transaction.value),\(transaction.balanceAccount?.currency ?? "nil"),\(transaction.category?.name ?? "nil"),\(transaction.balanceAccount?.name ?? "nil"),\(transaction.comment.isEmpty ? "" : transaction.comment),\(tagsNames.isEmpty ? "" : tagsNames)\n")
        }
        
        let fileManager = FileManager.default
        
        let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
        let fileURL = path.appendingPathComponent("Transactions.csv")
        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}
