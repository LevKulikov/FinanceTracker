//
//  SpendIncomeViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 25.05.2024.
//

import Foundation
import SwiftUI

final class SpendIncomeViewModel: ObservableObject {
    //MARK: - Properties
    private let dataManager: any DataManagerProtocol
    var currentDate: Date {
        Date.now
    }
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
    }
    
    //MARK: - Methods
}
