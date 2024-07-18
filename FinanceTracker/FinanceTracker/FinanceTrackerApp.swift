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
    @StateObject private var dataManager: DataManager

    var body: some Scene {
        WindowGroup {            
            FTFactory.shared.createCustomTabView(dataManager: dataManager)
                .preferredColorScheme(dataManager.preferredColorScheme)
        }
    }
    
    //MARK: Init
    init() {
        sharedModelContainer = Self.createModelContainer()
        let dm = DataManager(container: sharedModelContainer)
        _dataManager = StateObject(wrappedValue: dm)
        setAppearance()
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
            Budget.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    private func setAppearance() {
        UITabBar.appearance().backgroundColor = UIColor.clear
        UITabBar.appearance().barTintColor = .clear
        UITabBar.appearance().isHidden = true
    }
}
