//
//  WideMultipleCategoryPickerView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 30.07.2024.
//

import SwiftUI
import SwiftData

struct WideMultipleCategoryPickerView: View {
    private let categories: [Category]
    @Binding private var selectedCategories: [Category]
    @Binding private var show: Bool
    
    init(categories: [Category], selectedCategories: Binding<[Category]>, show: Binding<Bool>) {
        self.categories = categories
        self._selectedCategories = selectedCategories
        self._show = show
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(categories) { category in
                    rowForCategory(category)
                }
            }
            .navigationTitle("All categories")
            .toolbar {
                Button("Done") {
                    show = false
                }
            }
        }
    }
    
    @MainActor @ViewBuilder
    private func rowForCategory(_ category: Category) -> some View {
        let contains = selectedCategories.contains(category)
        
        HStack {
            FTAppAssets.iconImageOrEpty(name: category.iconName)
                .frame(width: 27, height: 27)
                .foregroundStyle(category.color)
            
            Text(category.name)
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(contains ? .blue : .gray)
                
                if contains {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                        .fontWeight(.medium)
                }
            }
            .frame(width: 27, height: 27)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            addRemoveCategory(category)
        }
    }
    
    private func addRemoveCategory(_ category: Category) {
        if let index = selectedCategories.firstIndex(of: category) {
            selectedCategories.remove(at: index)
        } else {
            selectedCategories.append(category)
        }
        print(selectedCategories)
    }
}

#Preview {
    @State var selectedCategories: [Category] = []
    let categories = try? DataManager(container: FinanceTrackerApp.createModelContainer()).fetch(FetchDescriptor<Category>())
    return WideMultipleCategoryPickerView(categories: categories ?? [], selectedCategories: $selectedCategories, show: .constant(true))
}
