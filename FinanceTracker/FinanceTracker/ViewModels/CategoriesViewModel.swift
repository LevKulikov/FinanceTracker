//
//  CategoriesViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 22.06.2024.
//

import Foundation
import SwiftData
import SwiftUI

protocol CategoriesViewModelDelegate: AnyObject, Sendable {
    func didUpdateCategoryList()
    
    func didDeleteCategory()
}

final class CategoriesViewModel: ObservableObject, @unchecked Sendable {
    //MARK: - Properties
    weak var delegate: (any CategoriesViewModelDelegate)?
    var filteredCategories: [Category] {
        allCategories.filter { $0.type == caterotyType }
    }
    
    //MARK: Private props
    private var dataManager: any DataManagerProtocol
    
    //MARK: Published props
    @Published private(set) var allCategories: [Category] = []
    @Published var caterotyType: TransactionsType = .spending
    @Published var startReordering = false {
        didSet {
            if startReordering {
                categoreisToReorder = filteredCategories
            }
        }
    }
    @Published private(set) var categoreisToReorder: [Category] = []
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
        fetchData(withAnimation: true)
    }
    
    //MARK: - Methods
    func fetchData(withAnimation: Bool = false, completionHandler: (@Sendable () -> Void)? = nil) {
        Task {
            await fetchCategories(withAnimation: withAnimation)
            completionHandler?()
        }
    }
    
    @MainActor
    func getAddingBalanceAccountView(for action: ActionWithCategory) -> some View {
        return FTFactory.shared.createAddingCategoryView(dataManager: dataManager, transactionType: caterotyType, action: action, delegate: self)
    }
    
    func deleteCategory(_ category: Category, moveTransactionsTo replacingCategory: Category) {
        Task { @MainActor [dataManager, delegate] in
            await dataManager.deleteCategory(category, moveTransactionsTo: replacingCategory)
            delegate?.didDeleteCategory()
            await fetchCategories()
        }
    }
    
    func deleteCategoryWithTransactions(_ category: Category) {
        Task { @MainActor [dataManager, delegate] in
            await dataManager.deleteCategoryWithTransactions(category)
            delegate?.didDeleteCategory()
            await fetchCategories()
        }
    }
    
    func moveCategoryPlacement(from: IndexSet, to: Int) {
        categoreisToReorder.move(fromOffsets: from, toOffset: to)
    }
    
    func saveReordering(refetchAfter: Bool) {
        defer { categoreisToReorder = [] }
        categoreisToReorder.forEach { category in
            guard let newIndex = categoreisToReorder.firstIndex(where: { $0.id == category.id }) else { return }
            category.placement = newIndex
        }
        Task { [dataManager] in
            try await dataManager.save()
            if refetchAfter {
                await fetchCategories()
            }
        }
    }
    
    //MARK: Private methods
    @MainActor
    private func fetchCategories(withAnimation animated: Bool = false, errorHandler: (@Sendable () -> Void)? = nil) async {
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.placement)])
        
        do {
            let fetchedData = try dataManager.fetch(descriptor)
            if animated {
                withAnimation {
                    allCategories = fetchedData
                }
            } else {
                allCategories = fetchedData
            }
        } catch {
            errorHandler?()
        }
    }
}


//MARK: - Extensions
//MARK: Extension for AddingCategoryViewModelDelegate
extension CategoriesViewModel: AddingCategoryViewModelDelegate {
    func didUpdateCategory() {
        fetchData()
        delegate?.didUpdateCategoryList()
    }
}
