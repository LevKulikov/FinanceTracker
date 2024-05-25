//
//  DataManager.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 25.05.2024.
//

import Foundation
import SwiftData

@MainActor
protocol DataManagerProtocol: AnyObject {
    func save() throws
    
    func delete<T>(_ model: T) where T : PersistentModel
    
    func insert<T>(_ model: T) where T : PersistentModel
    
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
    
    func delete<T>(_ model: T) where T : PersistentModel {
        container.mainContext.delete(model)
    }
    
    func insert<T>(_ model: T) where T : PersistentModel {
        container.mainContext.insert(model)
    }
    
    func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] where T : PersistentModel {
        return try container.mainContext.fetch(descriptor)
    }
}
