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
            title: "Simple",
            text: "Easily add your expenses and income",
            imageName: "list page example"
        ),
        .init(
            title: "Graphs",
            text: "Track your finances with customizable graphs",
            imageName: "statistics page example"),
        .init(
            title: "Open source",
            text: "Completely open source, all information is stored on your device. No need to worry about privacy!",
            imageName: "github in safari"
        ),
        .init(
            title: "First step",
            text: "Create your balance account to start",
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
