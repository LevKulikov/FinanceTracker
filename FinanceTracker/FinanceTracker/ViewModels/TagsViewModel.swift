//
//  TagsViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 24.06.2024.
//

import Foundation
import SwiftData
import SwiftUI

protocol TagsViewModelDelegate: AnyObject {
    
}

final class TagsViewModel: ObservableObject {
    //MARK: - Properties
    weak var delegate: (any TagsViewModelDelegate)?
    
    //MARK: Pivate properties
    private let dataManager: any DataManagerProtocol
    
    //MARK: Published properties
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
    }
    
    //MARK: - Methods
    
    //MARK: Pivate methods
}
