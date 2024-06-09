//
//  AddingCategoryViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 05.06.2024.
//

import Foundation
import SwiftUI
import SwiftData

protocol AddingCategoryViewModelDelegate: AnyObject {
    func didUpdateCategory()
}

final class AddingCategoryViewModel: ObservableObject {
    //MARK: - Properties
    private let dataManager: any DataManagerProtocol
    weak var delegate: (any AddingCategoryViewModelDelegate)?
    var filteredCategories: [Category] {
        guard !name.isEmpty else { return [] }
        
        return availableCategories.filter {
            $0.name.lowercased().contains(name.lowercased())
        }
    }
    var categoryPreview: Category {
        Category(
            type: transactionType,
            name: name,
            iconName: iconName,
            color: categoryColor
        )
    }
    let defaultColors: [Color] = [
        .red,
        .blue,
        .green,
        .orange,
        .purple,
        .yellow,
    ]
    
    //MARK: Published props
    @Published private(set) var availableCategories: [Category] = []
    @Published var transactionType: TransactionsType = .spending {
        didSet {
            Task {
                await fetchCategories()
            }
        }
    }
    @Published var name: String = ""
    @Published var iconName: String = ""
    @Published var categoryColor: Color
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol, transactionType: TransactionsType) {
        self.dataManager = dataManager
        self.transactionType = transactionType
        self.categoryColor = transactionType == .spending ? .red : .green
        Task {
            await fetchCategories()
        }
    }
    
    //MARK: - Methods
    //MARK: Internal methods
    func saveCategory(completionHandler: @escaping () -> Void ) {
        guard !name.isEmpty else { return }
        guard !iconName.isEmpty else { return }
        
        let newCategory = Category(
            type: transactionType,
            name: name,
            iconName: iconName,
            color: categoryColor
        )
        Task {
            await dataManager.insert(newCategory)
            delegate?.didUpdateCategory()
            completionHandler()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.removeAndRefetch()
            }
        }
    }
    
    //MARK: Private methods
    /// This method is needed to check if such category exists
    @MainActor
    private func fetchCategories(errorHandler: ((Error) -> Void)? = nil) async {
        // It is needed to prevent Predicate type convertion error (cannot reference an object property inside of a Predicate)
        let rawValue = transactionType.rawValue
        
        let predicate = #Predicate<Category> {
            $0.typeRawValue == rawValue
        }
        
        guard let fetchedCategories = await fetch(withPredicate: predicate) else {
            errorHandler?(FetchErrors.unableToFetchCategories)
            return
        }
        
        withAnimation(.snappy) {
            availableCategories = fetchedCategories
        }
    }
    
    private func fetch<T>(withPredicate: Predicate<T>? = nil, sortWithString keyPath: KeyPath<T, String>? = nil) async -> [T]? where T: PersistentModel {
        let descriptor = FetchDescriptor<T>(
            predicate: withPredicate,
            sortBy: keyPath == nil ? [] : [SortDescriptor(keyPath!)]
        )
        
        do {
            var fetchedItems = try await dataManager.fetch(descriptor)
            if keyPath == nil {
                fetchedItems.reverse()
            }
            return fetchedItems
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    private func removeAndRefetch() {
        withAnimation {
            name = ""
            iconName = ""
        }
        Task {
            await fetchCategories()
        }
    }
}
