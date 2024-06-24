//
//  TagsView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 24.06.2024.
//

import SwiftUI

struct TagsView: View {
    //MARK: - Properties
    @StateObject private var viewModel: TagsViewModel
    
    //MARK: - Initializer
    init(viewModel: TagsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
    
    //MARK: - Computed View props
    
    //MARK: - Methods
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = TagsViewModel(dataManager: dataManger)
    
    return TagsView(viewModel: viewModel)
}
