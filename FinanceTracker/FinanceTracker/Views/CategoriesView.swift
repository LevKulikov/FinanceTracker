//
//  CategoriesView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 22.06.2024.
//

import SwiftUI

struct CategoriesView: View {
    //MARK: - Properties
    @StateObject private var viewModel: CategoriesViewModel
    @State private var navigationPath = NavigationPath()
    
    //MARK: - Initializer
    init(viewModel: CategoriesViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 110))]) {
                    ForEach(viewModel.filteredCategories) { category in
                        CategoryItemView(category: category, selectedCategory: .constant(nil))
                    }
                }
            }
            .navigationTitle("Categories")
            .navigationDestination(for: ActionWithCategory.self) { action in
                viewModel.getAddingBalanceAccountView(for: action)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    typePickerView
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        navigationPath.append(ActionWithCategory.add)
                    }
                }
            }
        }
    }
    
    //MARK: - Computed View Props
    private var typePickerView: some View {
        Picker("Type picker", selection: $viewModel.caterotyType) {
            Text(TransactionsType.spending.rawValue)
                .tag(TransactionsType.spending)
            
            Text(TransactionsType.income.rawValue)
                .tag(TransactionsType.income)
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .frame(maxWidth: 250)
    }
    
    //MARK: - Methods
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = CategoriesViewModel(dataManager: dataManger)
    
    return CategoriesView(viewModel: viewModel)
}
