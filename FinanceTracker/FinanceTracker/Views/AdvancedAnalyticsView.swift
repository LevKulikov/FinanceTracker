//
//  AdvancedAnalyticsView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 02.12.2024.
//

import SwiftUI

struct AdvancedAnalyticsView: View {
    //MARK: - Properties
    @StateObject private var viewModel: AdvancedAnalyticsViewModel
    
    //MARK: - Initializer
    init(viewModel: AdvancedAnalyticsViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    //MARK: - Computed View Properties
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
    
    //MARK: - Methods AdvancedAnalyticsViewModel
}

#Preview {
    let dataManager = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = AdvancedAnalyticsViewModel(dataManager: dataManager)
    AdvancedAnalyticsView(viewModel: viewModel)
}
