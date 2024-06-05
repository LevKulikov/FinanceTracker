//
//  AddingCategoryView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 05.06.2024.
//

import SwiftUI

struct AddingCategoryView: View {
    //MARK: Properties
    @StateObject private var viewModel: AddingCategoryViewModel
    
    //MARK: Init
    init(viewModel: AddingCategoryViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: Body
    var body: some View {
        Text("Hello, World!")
    }
    //MARK: View Propeties
    
    //MARK: Methods
    
}

#Preview {
    let container = FinanceTrackerApp.createModelContainer()
    let dataManager = DataManager(container: container)
    let viewModel = AddingCategoryViewModel(dataManager: dataManager, transactionType: .spending)
    
    return AddingCategoryView(viewModel: viewModel)
}
