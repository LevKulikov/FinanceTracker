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
    private var sharedModelContainer: ModelContainer
    private var dataManager: DataManager

    var body: some Scene {
        WindowGroup {            
            FTFactory.createCustomTabView(dataManager: dataManager)
        }
    }
    
    //MARK: Init
    init() {
        sharedModelContainer = Self.createModelContainer()
        dataManager = DataManager(container: sharedModelContainer)
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
}
