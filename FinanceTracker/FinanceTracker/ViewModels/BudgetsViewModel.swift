//
//  BudgetsViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 18.07.2024.
//

import Foundation

//MARK: - Delegate protocol
protocol BudgetsViewModelDelegate: AnyObject {
    
}

//MARK: - ViewModel class
final class BudgetsViewModel: ObservableObject {
    //MARK: - Properties
    weak var delegate: (any BudgetsViewModelDelegate)?
    
    //MARK: Private properties
    private let dataManager: any DataManagerProtocol
    
    //MARK: - Initializer
    init(dataManager: any DataManagerProtocol) {
        self.dataManager = dataManager
    }
    
    //MARK: - Methods
}

//MARK: - Extensions
