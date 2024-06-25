//
//  CategoriesView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 22.06.2024.
//

import SwiftUI

struct CategoriesView: View {
    enum WhatIsReplaced: Equatable {
        case deleteCategory
        case replaceToCategory
    }
    
    //MARK: - Properties
    @Namespace private var namespace
    @StateObject private var viewModel: CategoriesViewModel
    @State private var navigationPath = NavigationPath()
    /// Flag for confirmation dialog
    @State private var categoryToDeleteFlag: Category?
    @State private var showReplacementSheet = false
    /// Category to be replaced and deleted
    @State private var categoryToDelete: Category? {
        didSet {
            if categoryToDelete == categoryToReplaceTo {
                categoryToReplaceTo = nil
            }
        }
    }
    @State private var categoryToReplaceTo: Category? {
        didSet {
            if categoryToDelete == categoryToReplaceTo {
                categoryToDelete = nil
            }
        }
    }
    @State private var whatIsReplaced: WhatIsReplaced?
    
    private let deleteCategoryId = "deleteCategoryId"
    private let replaceToCategoryId = "replaceToCategoryId"
    private let toTextId = "toTextId"
    private let fromTextId = "fromTextId"
    
    //MARK: - Initializer
    init(viewModel: CategoriesViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 120))]) {
                    ForEach(viewModel.filteredCategories) { category in
                        CategoryItemView(category: category, selectedCategory: .constant(nil))
                            .onTapGesture {
                                navigationPath.append(ActionWithCategory.update(category))
                            }
                            .contextMenu {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    categoryToDeleteFlag = category
                                }
                            }
                    }
                }
                .padding(.vertical)
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
            .sheet(isPresented: $showReplacementSheet) {
                replacmentView
                    .presentationDetents([.height(350)])
                    .presentationBackground(Material.thin)
                    .presentationCornerRadius(30)
            }
            .confirmationDialog(
                "Delete category?",
                isPresented: .init(get: { categoryToDeleteFlag != nil }, set: { _ in categoryToDeleteFlag = nil }),
                titleVisibility: .visible) {
                    Button("Delete category only") {
                        categoryToDelete = categoryToDeleteFlag
                        showReplacementSheet.toggle()
                    }
                    
                    Button("Delete with transactions", role: .destructive) {
                        if let categoryToDeleteFlag {
                            viewModel.deleteCategoryWithTransactions(categoryToDeleteFlag)
                        }
                    }
                } message: {
                    Text("This action is irretable. There are two ways to delete:\n\n - Delete category only: all transactions binded to deleted category will be moved to another one of your choice. Before deletion app will ask you where transactions should be moved to\n\n - Delete with transactions: category and binded to it transactions will be deleted all together")
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
    
    private var replacmentView: some View {
        VStack {
            Text("Move transactions")
                .font(.title2)
                .bold()
                .padding()
            
            if let whatIsReplaced {
                scrollForSelection(whichCategory: whatIsReplaced)
                    .padding(.horizontal, 25)
                    .padding(.bottom)
                
            } else {
                categoryToReplaceSelectionView
                    .padding(.horizontal, 25)
                    .padding(.bottom)
            }
            
            Spacer()
            
            Button("Replace and delete", role: .destructive) {
                if let categoryToDelete, let categoryToReplaceTo, categoryToDelete != categoryToReplaceTo {
                    viewModel.deleteCategory(categoryToDelete, moveTransactionsTo: categoryToReplaceTo)
                }
                showReplacementSheet.toggle()
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .disabled(categoryToReplaceTo == nil)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                whatIsReplaced = nil
            }
        }
    }
    
    private var categoryToReplaceSelectionView: some View {
        HStack {
            VStack {
                Text("From")
                    .foregroundStyle(.secondary)
                    .matchedGeometryEffect(id: fromTextId, in: namespace)
                
                if let categoryToDelete {
                    CategoryItemView(category: categoryToDelete, selectedCategory: .constant(nil))
                } else {
                    Text("Select")
                        .foregroundStyle(.blue)
                        .frame(width: 100, height: 130)
                }
            }
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.secondarySystemBackground))
                    .matchedGeometryEffect(id: deleteCategoryId, in: namespace)
            }
            .onTapGesture {
                withAnimation {
                    whatIsReplaced = .deleteCategory
                }
            }
            
            Spacer()
            
            Image(systemName: "arrowshape.right")
                .font(.system(size: 50))
                .padding(.horizontal)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            VStack {
                Text("To")
                    .foregroundStyle(.secondary)
                    .matchedGeometryEffect(id: toTextId, in: namespace)
                
                if let categoryToReplaceTo {
                    CategoryItemView(category: categoryToReplaceTo, selectedCategory: .constant(nil))
                } else {
                    Text("Select")
                        .foregroundStyle(.blue)
                        .frame(width: 100, height: 130)
                }
            }
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.secondarySystemBackground))
                    .matchedGeometryEffect(id: replaceToCategoryId, in: namespace)
            }
            .onTapGesture {
                withAnimation {
                    whatIsReplaced = .replaceToCategory
                }
            }
        }
    }
    
    //MARK: - Methods
    @ViewBuilder
    private func scrollForSelection(whichCategory: WhatIsReplaced) -> some View {
        VStack {
            Text(whichCategory == .replaceToCategory ? "To" : "From")
                .foregroundStyle(.secondary)
                .matchedGeometryEffect(id: whichCategory == .replaceToCategory ? toTextId : fromTextId, in: namespace)
                .frame(maxWidth: .infinity, alignment: whichCategory == .replaceToCategory ? .trailing : .leading)
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(viewModel.filteredCategories) { category in
                        CategoryItemView(category: category, selectedCategory: .constant(nil))
                            .onTapGesture {
                                if whichCategory == .replaceToCategory {
                                    categoryToReplaceTo = category
                                } else {
                                    categoryToDelete = category
                                }
                                
                                withAnimation {
                                    whatIsReplaced = nil
                                }
                            }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.secondarySystemBackground))
                .matchedGeometryEffect(id: whichCategory == .replaceToCategory ? replaceToCategoryId : deleteCategoryId, in: namespace)
        }
    }
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = CategoriesViewModel(dataManager: dataManger)
    
    return CategoriesView(viewModel: viewModel)
}
