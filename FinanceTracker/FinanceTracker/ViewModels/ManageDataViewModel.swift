//
//  ManageDataViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 25.06.2024.
//

import Foundation

protocol ManageDataViewModelDelegate: AnyObject {
    func didDeleteAllData()
}

final class ManageDataViewModel: ObservableObject {
    //MARK: - Properties
    weak var delegate: (any ManageDataViewModelDelegate)?
    
    //MARK: Private props
    private let dataManager: any DataManagerProtocol
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
    }
    
    //MARK: - Methods
    func deleteAllStoredData() {
        dataManager.deleteAllStoredData()
    }
}
