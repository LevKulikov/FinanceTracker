//
//  WelcomeViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 30.06.2024.
//

import Foundation
import SwiftUI

protocol WelcomeViewModelDelegate: AnyObject {
    func didCreateBalanceAccount()
}

struct ExampleModel: Identifiable {
    let id = UUID().uuidString
    let title: String
    let text: String
    let imageName: String
}

final class WelcomeViewModel: ObservableObject {
    //MARK: - Properties
    weak var delegate: (any WelcomeViewModelDelegate)?
    let models: [ExampleModel] = [
        .init(
            title: String(localized: "Simple"),
            text: String(localized: "Easily add your expenses and income"),
            imageName: "list page example"
        ),
        .init(
            title: String(localized: "Graphs"),
            text: String(localized: "Track your finances with customizable graphs"),
            imageName: "statistics page example"),
        .init(
            title: String(localized: "Open source"),
            text: String(localized: "Completely open source, all information is stored on your device. No need to worry about privacy!"),
            imageName: "github in safari"
        ),
        .init(
            title: String(localized: "First step"),
            text: String(localized: "Create your balance account to start"),
            imageName: "confirm image gray")
    ]
    
    //MARK: Private props
    private let dataManager: any DataManagerProtocol
    
    //MARK: Published
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
    }
    
    //MARK: - Methods
    func getAddingBalanceAccauntView() -> some View {
        return FTFactory.shared.createAddingBalanceAccauntView(dataManager: dataManager, action: .add, delegate: self)
    }
    
    func welcomeIsPassed() {
        dataManager.isFirstLaunch = false
        // NotificationManager ask for notifications permition during init
        NotificationManager.askForPermition()
        Task {
            await dataManager.saveDefaultCategories()
        }
    }
    
    //MARK: Private methods
    
}

//MARK: - Extensions
extension WelcomeViewModel: AddingBalanceAccountViewModelDelegate {
    func didUpdateBalanceAccount(_ balanceAccount: BalanceAccount) {
        dataManager.setDefaultBalanceAccount(balanceAccount)
        delegate?.didCreateBalanceAccount()
    }
}
