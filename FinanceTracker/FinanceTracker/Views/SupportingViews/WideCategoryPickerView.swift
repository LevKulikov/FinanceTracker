//
//  WideCategoryPickerView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 20.07.2024.
//

import SwiftUI

struct WideCategoryPickerView<Content: View, MenuItems: View>: View {
    let categories: [Category]
    @Binding var selecetedCategory: Category?
    @Binding var show: Bool
    let isAddingAvailable: Bool
    @ViewBuilder let addingNavigationView: Content
    let onTapAction: (Category) -> Void
    @ViewBuilder let contextMenuContent: (Category) -> MenuItems
    
    init(
        categories: [Category],
        selecetedCategory: Binding<Category?>,
        show: Binding<Bool>,
        isAddingAvailable: Bool,
        addingNavigationView: Content,
        onTapAction: @escaping (Category) -> Void,
        @ViewBuilder contextMenuContent: @escaping (Category) -> MenuItems
    ) {
        self.categories = categories
        self._selecetedCategory = selecetedCategory
        self._show = show
        self.isAddingAvailable = isAddingAvailable
        self.addingNavigationView = addingNavigationView
        self.onTapAction = onTapAction
        self.contextMenuContent = contextMenuContent
    }
    
    init(
        categories: [Category],
        selecetedCategory: Binding<Category?>,
        show: Binding<Bool>,
        onTapAction: @escaping (Category) -> Void,
        contextMenuContent: @escaping (Category) -> MenuItems
    ) where Content == EmptyView {
        self.categories = categories
        self._selecetedCategory = selecetedCategory
        self._show = show
        self.isAddingAvailable = false
        self.addingNavigationView = EmptyView()
        self.onTapAction = onTapAction
        self.contextMenuContent = contextMenuContent
    }
    
    init(
        categories: [Category],
        selecetedCategory: Binding<Category?>,
        show: Binding<Bool>,
        addingNavigationView: Content,
        onTapAction: @escaping (Category) -> Void,
        @ViewBuilder contextMenuContent: @escaping (Category) -> MenuItems
    ) {
        self.categories = categories
        self._selecetedCategory = selecetedCategory
        self._show = show
        self.isAddingAvailable = true
        self.addingNavigationView = addingNavigationView
        self.onTapAction = onTapAction
        self.contextMenuContent = contextMenuContent
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("All Categories")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button("Close") {
                        show = false
                    }
                    .hoverEffect(.highlight)
                }
                .padding(.top, 20)
                .padding(.horizontal, 25)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 110))]) {
                        ForEach(categories) { categoryToSet in
                            CategoryItemView(category: categoryToSet, selectedCategory: $selecetedCategory)
                                .hoverEffect(.lift)
                                .onTapGesture {
                                    onTapAction(categoryToSet)
                                }
                                .contextMenu {
                                    contextMenuContent(categoryToSet)
                                }
                        }
                        
                        if isAddingAvailable {
                            NavigationLink {
                                addingNavigationView
                            } label: {
                                Image(systemName: "plus")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 50, weight: .medium))
                                    .padding(8)
                                    .background {
                                        Circle()
                                            .fill(.blue)
                                    }
                            }
                            .frame(width: 100, height: 130)
                        }
                    }
                }
                .contentMargins(10, for: .scrollContent)
            }
        }
    }
}

#Preview {
    
    
    WideCategoryPickerView(categories: [], selecetedCategory: .constant(nil), show: .constant(true)) { category in
        print(category.name)
    } contextMenuContent: { category in
        Button("Update") {
            
        }
    }
}
