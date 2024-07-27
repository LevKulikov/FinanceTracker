//
//  TabsSettingsView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 27.07.2024.
//

import SwiftUI

struct TabsSettingsView: View {
    //MARK: - Properties
    @StateObject private var viewModel: TabsSettingsViewModel
    
    //MARK: - Initializer
    init(viewModel: TabsSettingsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                Section("Drag to reorder") {
                    ForEach(viewModel.changableTabs) { tab in
                        rowForTab(tab)
                    }
                    .onMove(perform: { indices, newOffset in
                        viewModel.moveTabs(indices: indices, newOffset: newOffset)
                    })
                }
            }
            .navigationTitle("Tabs placements")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    //MARK: - Methods
    @ViewBuilder
    private func rowForTab(_ tab: TabViewType) -> some View {
        let isHidden = (viewModel.changableTabs.firstIndex(of: tab) ?? 0) > (viewModel.numberOfTabsThatCanBeSet - 1)
        
        HStack {
            tab.tabImage
                .foregroundStyle(isHidden ? Color.secondary : Color.blue)
                .frame(width: 25)
            
            Text(tab.tabTitle)
            
            Spacer()
            
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)
        }
        .foregroundStyle(isHidden ? Color.secondary : Color.primary)
    }
}

#Preview {
    let dataManager = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = TabsSettingsViewModel(dataManager: dataManager)
    
    return TabsSettingsView(viewModel: viewModel)
}
