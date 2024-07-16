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
    @Environment(\.colorScheme) var colorScheme
    @Namespace private var namespace
    @StateObject private var viewModel: CategoriesViewModel
    @State private var navigationPath = NavigationPath()
    /// Flag for confirmation dialog
    @State private var categoryToDeleteFlag: Category?
    @State private var showReplacementSheet = false
    /// Category to be replaced and deleted
    @State private var categoryToDelete: Category? {
        didSet {
            if let categoryToDelete, categoryToDelete == categoryToReplaceTo {
                categoryToReplaceTo = nil
            }
        }
    }
    @State private var categoryToReplaceTo: Category? {
        didSet {
            if let categoryToReplaceTo, categoryToDelete == categoryToReplaceTo {
                categoryToDelete = nil
            }
        }
    }
    @State private var whatIsReplaced: WhatIsReplaced?
    @State private var rotateReplaceArrow = false
    
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
                VStack {
                    HStack {
                        Button {
                            viewModel.startReordering = true
                        } label: {
                            Label("Reorder", systemImage: "list.dash")
                                .frame(maxWidth: .infinity)
                        }
                        .hoverEffect(.lift)
                    }
                    .padding()
                    .buttonStyle(.bordered)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 120))]) {
                        ForEach(viewModel.filteredCategories) { category in
                            CategoryItemView(category: category, selectedCategory: .constant(nil))
                                .hoverEffect(.lift)
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
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let xTrans = value.translation.width
                        let screenWidth = FTAppAssets.getWindowSize().width
                        // plus is back, minus is forward
                        if abs(xTrans) > screenWidth / 4 {
                            if xTrans > 0 {
                                viewModel.caterotyType = .spending
                            } else {
                                viewModel.caterotyType = .income
                            }
                        }
                    }
            )
            .sheet(isPresented: $showReplacementSheet) {
                replacmentView
                    .presentationDetents([.height(350)])
                    .presentationBackground(Material.thin)
                    .presentationCornerRadius(30)
            }
            .sheet(isPresented: $viewModel.startReordering) {
                reorderView
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
    
    private var reorderView: some View {
        VStack(spacing: 0) {
            Text("Drag and drop to reorder")
                .padding()
                .frame(maxWidth: .infinity)
                .foregroundStyle(.secondary)
                .bold()
                .background {
                    Rectangle()
                        .fill(colorScheme == .light ? Color(.systemGray6) : .clear)
                }
            
            List {
                ForEach(viewModel.categoreisToReorder) { category in
                    HStack {
                        FTAppAssets.iconImageOrEpty(name: category.iconName)
                            .frame(width: 20, height: 20)
                            .foregroundStyle(category.color)
                        
                        Text(category.name)
                        
                        Spacer()
                        
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.tertiary)
                    }
                }
                .onMove(perform: { from, to in
                    viewModel.moveCategoryPlacement(from: from, to: to)
                })
                
                Section {
                    Rectangle()
                        .fill(.clear)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .overlay(alignment: .bottom) {
            Button {
                viewModel.saveReordering(refetchAfter: true)
                viewModel.startReordering = false
            } label: {
                Text("Save")
                    .frame(height: 25)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .padding(.horizontal)
        }
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
            .disabled((categoryToReplaceTo == nil || categoryToDelete == nil || categoryToReplaceTo == categoryToDelete))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                whatIsReplaced = nil
            }
        }
        .frame(maxWidth: 450, maxHeight: 400)
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
                .rotationEffect(.degrees(rotateReplaceArrow ? 360 : 0))
                .onTapGesture {
//                    categoryToReplaceTo  categoryToDelete
                    let buffer = categoryToReplaceTo
                    withAnimation {
                        rotateReplaceArrow.toggle()
                        categoryToReplaceTo = categoryToDelete
                        categoryToDelete = buffer
                    }
                }
            
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
