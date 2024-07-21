//
//  BackgroundDataActor.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 05.07.2024.
//

import Foundation
import SwiftData

@ModelActor
actor BackgroundDataActor {
    //MARK: - Methods
    func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] where T : PersistentModel {
        return try modelContext.fetch(descriptor)
    }
    
    func insert<T>(_ model: T) where T : PersistentModel {
        modelContext.insert(model)
    }
    
    func save() throws {
        try modelContext.save()
    }
    
    func delete<T>(_ model: T) where T : PersistentModel {
        modelContext.delete(model)
    }
    
    func deleteTransactionById(_ transaction: Transaction) throws {
        let trId = transaction.id
        let descr = FetchDescriptor<Transaction>(predicate: #Predicate<Transaction> { $0.id == trId })
        let arr = try fetch(descr)
        guard let backTr = arr.first else { return }
        delete(backTr)
    }
}
