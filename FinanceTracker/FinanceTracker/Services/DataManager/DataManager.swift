//
//  DataManager.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 25.05.2024.
//

import Foundation
import SwiftData

protocol DataManagerProtocol: AnyObject {
    @MainActor
    func save() throws
    
    @MainActor
    func deleteTransaction(_ transaction: Transaction)
    
    @MainActor
    func insert<T>(_ model: T) where T : PersistentModel
    
    @MainActor
    func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] where T : PersistentModel
}

final class DataManager: DataManagerProtocol {
    //MARK: Properties
    private let container: ModelContainer
    
    //MARK: Init
    init(container: ModelContainer) {
        self.container = container
    }
    
    //MARK: Methods
    func save() throws {
        try container.mainContext.save()
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        container.mainContext.delete(transaction)
    }
    
    func insert<T>(_ model: T) where T : PersistentModel {
        container.mainContext.insert(model)
    }
    
    func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] where T : PersistentModel {
        return try container.mainContext.fetch(descriptor)
    }
}
