//
//  FinanceTrackerApp.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 24.05.2024.
//

import SwiftUI
import SwiftData

@main
struct FinanceTrackerApp: App {
    //MARK: Properties
    var sharedModelContainer: ModelContainer?

    var body: some Scene {
        WindowGroup {
            createSpendIncomeView(container: sharedModelContainer!)
        }
    }
    
    //MARK: Methods
    init() {
        sharedModelContainer = Self.createModelContainer()
    }
    
    //MARK: Methods
    ///This method is static, because it is used in Previews
    static func createModelContainer() -> ModelContainer {
        UIColorValueTransformer.register()
        
        let schema = Schema([
            BalanceAccount.self,
            Category.self,
            Tag.self,
            Transaction.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    @MainActor @ViewBuilder
    private func createSpendIncomeView(container: ModelContainer) -> some View {
        let dataManager = DataManager(container: container)
        let viewModel = SpendIncomeViewModel(dataManager: dataManager)
        
        SpendIncomeView(viewModel: viewModel)
    }
}
