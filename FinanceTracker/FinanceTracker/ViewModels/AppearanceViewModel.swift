//
//  AppearanceViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 25.06.2024.
//

import Foundation
import SwiftUI

protocol AppearanceViewModelDelegate: AnyObject {
    func didSetShowAddButtonFromEvetyTab(_ show: Bool)
}

final class AppearanceViewModel: ObservableObject {
    //MARK: - Properties
    weak var delegate: AppearanceViewModelDelegate?
    private let dataManager: any DataManagerProtocol
    
    //MARK: Published props
    @MainActor @Published var showAddButtonFromEvetyTab: Bool {
        didSet {
            dataManager.showAddButtonFromEvetyTab(showAddButtonFromEvetyTab)
            delegate?.didSetShowAddButtonFromEvetyTab(showAddButtonFromEvetyTab)
        }
    }
    @MainActor @Published private(set) var preferredColorScheme: ColorScheme?
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
        self._showAddButtonFromEvetyTab = Published(wrappedValue: dataManager.showAddButtonFromEvetyTab())
        self._preferredColorScheme = Published(wrappedValue: dataManager.getPreferredColorScheme())
    }
    
    //MARK: - Methods
    @MainActor
    func setPreferredColorScheme(_ colorScheme: ColorScheme?) {
        dataManager.setPreferredColorScheme(colorScheme)
        withAnimation {
            preferredColorScheme = colorScheme
        }
    }
    
    //MARK: Private methods
    
}
