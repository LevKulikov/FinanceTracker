//
//  AddingBudgetView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 20.07.2024.
//

import SwiftUI

struct AddingBudgetView: View {
    //MARK: - Properties
    @StateObject private var viewModel: AddingBudgetViewModel
    
    //MARK: - Initializer
    init(viewModel: AddingBudgetViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        ScrollView {
            
            Rectangle()
                .fill(.clear)
                .frame(height: 50)
        }
        .scrollIndicators(.hidden)
    }
    
    //MARK: - Computed view props
    
    //MARK: - Methods
}

#Preview {
    let dataManager = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = AddingBudgetViewModel(action: .update(budget: .empty), dataManager: dataManager)
    
    return AddingBudgetView(viewModel: viewModel)
}
