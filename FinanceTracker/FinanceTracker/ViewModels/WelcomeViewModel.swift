//
//  WelcomeViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 30.06.2024.
//

import Foundation
import SwiftUI

protocol WelcomeViewModelDelegate: AnyObject {
    
}

struct ExampleModel: Identifiable {
    let id = UUID().uuidString
    let title: String
    let text: String
    let imageName: String
}

final class WelcomeViewModel: ObservableObject {
    //MARK: - Properties
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
    
    //MARK: Private methods
    
}

//MARK: - Extensions
extension WelcomeViewModel: AddingBalanceAccountViewModelDelegate {
    func didUpdateBalanceAccount() {
        //TODO: Complete
    }
}
