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
    
    //MARK: - Initializer
    init(viewModel: CategoriesViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
    
    //MARK: - Computed View Props
    
    
    //MARK: - Methods
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = CategoriesViewModel(dataManager: dataManger)
    
    return CategoriesView(viewModel: viewModel)
}
