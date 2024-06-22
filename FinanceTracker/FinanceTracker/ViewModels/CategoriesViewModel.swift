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
        fetchData()
    }
    
    //MARK: - Methods
    func fetchData(completionHandler: (() -> Void)? = nil) {
        Task {
            await fetchCategories()
            completionHandler?()
        }
    }
    
    func getAddingBalanceAccountView(for action: ActionWithCategory) -> some View {
        return FTFactory.createAddingCategoryView(dataManager: dataManager, transactionType: caterotyType, action: action, delegate: self)
    }
    
    //MARK: Private methods
    @MainActor
    private func fetchCategories(errorHandler: (() -> Void)? = nil) {
        let descriptor = FetchDescriptor<Category>()
        do {
            let fetchedData = try dataManager.fetch(descriptor)
            withAnimation {
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
    }
}
