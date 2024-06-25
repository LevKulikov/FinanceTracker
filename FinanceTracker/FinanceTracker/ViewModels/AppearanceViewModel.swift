//
//  AppearanceViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 25.06.2024.
//

import Foundation
import SwiftUI

final class AppearanceViewModel: ObservableObject {
    //MARK: - Properties
    private let dataManager: any DataManagerProtocol
    
    //MARK: Published props
    @Published private(set) var preferredColorScheme: ColorScheme? = nil
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
        self.preferredColorScheme = dataManager.getPreferredColorScheme()
    }
    
    //MARK: - Methods
    func setPreferredColorScheme(_ colorScheme: ColorScheme?) {
        dataManager.setPreferredColorScheme(colorScheme)
        withAnimation {
            preferredColorScheme = colorScheme
        }
    }
    
    //MARK: Private methods
    
}
