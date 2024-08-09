//
//  ManageDataViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 25.06.2024.
//

import Foundation

protocol ManageDataViewModelDelegate: AnyObject {
    func didDeleteAllTransactions()
    
    func didDeleteAllData()
}

final class ManageDataViewModel: ObservableObject, @unchecked Sendable {
    //MARK: - Properties
    weak var delegate: (any ManageDataViewModelDelegate)?
    
    //MARK: Published
    @MainActor @Published private(set) var isDataFetchingForExport = false
    @MainActor @Published var fileToExport: URL?
    @MainActor @Published var dataExportError: Error?
    
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
        Task {
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
                    dataExportError = error
                    isDataFetchingForExport = false
                }
                return
            }
        }
    }
}
