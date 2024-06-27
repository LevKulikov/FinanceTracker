//
//  SearchView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 27.06.2024.
//

import SwiftUI

struct SearchView: View {
    //MARK: - Properties
    @StateObject private var viewModel: SearchViewModel
    @State private var navigationPath = NavigationPath()
    
    //MARK: - Initializer
    init(viewModel: SearchViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                
            }
            .navigationTitle("Search")
        }
        .searchable(text: $viewModel.searchText, prompt: Text("Any text or number"))
    }
    
    //MARK: - Computed View props
    private var filterView: some View {
        VStack {
            
        }
    }
    
    //MARK: - Methods
    
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = SearchViewModel(dataManager: dataManger)
    
    return SearchView(viewModel: viewModel)
}
