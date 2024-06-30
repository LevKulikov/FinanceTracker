//
//  WelcomeViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 30.06.2024.
//

import Foundation

protocol WelcomeViewModelDelegate: AnyObject {
    
}

final class WelcomeViewModel: ObservableObject {
    //MARK: - Properties
    
    //MARK: Private props
    private let dataManager: any DataManagerProtocol
    
    //MARK: Published
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
    }
    
    //MARK: - Methods
    
    //MARK: Private methods
}
