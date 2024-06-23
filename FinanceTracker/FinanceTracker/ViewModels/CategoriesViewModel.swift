//
//  CategoriesViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 22.06.2024.
//

import Foundation
import SwiftData
import SwiftUI

protocol CategoriesViewModelDelegate: AnyObject {
    func didUpdateCategoryList()
    
    func didDeleteCategory()
}

final class CategoriesViewModel: ObservableObject {
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
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
        fetchData(withAnimation: true)
    }
    
    //MARK: - Methods
    func fetchData(withAnimation: Bool = false, completionHandler: (() -> Void)? = nil) {
        Task {
            await fetchCategories(withAnimation: withAnimation)
            completionHandler?()
        }
    }
    
    func getAddingBalanceAccountView(for action: ActionWithCategory) -> some View {
        return FTFactory.createAddingCategoryView(dataManager: dataManager, transactionType: caterotyType, action: action, delegate: self)
    }
    
    func deleteCategory(_ category: Category, moveTransactionsTo replacingCategory: Category) {
        Task { @MainActor in
            await dataManager.deleteCategory(category, moveTransactionsTo: replacingCategory)
            delegate?.didDeleteCategory()
            await fetchCategories()
        }
    }
    
    func deleteCategoryWithTransactions(_ category: Category) {
        Task { @MainActor in
            await dataManager.deleteCategoryWithTransactions(category)
            delegate?.didDeleteCategory()
            await fetchCategories()
        }
    }
    
    //MARK: Private methods
    @MainActor
    private func fetchCategories(withAnimation animated: Bool = false, errorHandler: (() -> Void)? = nil) async {
        let descriptor = FetchDescriptor<Category>()
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
