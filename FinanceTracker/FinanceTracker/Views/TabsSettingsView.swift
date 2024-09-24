//
//  TabsSettingsView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 27.07.2024.
//

import SwiftUI

struct TabsSettingsView: View {
    //MARK: - Properties
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: TabsSettingsViewModel
    private var footerText: LocalizedStringResource {
        if viewModel.changedSettingsPosition {
            return "As you have changed the position of the Settings tab, click Save to apply the changes"
        } else {
            return "Changes are saved automatically"
        }
    }
    
    //MARK: - Initializer
    init(viewModel: TabsSettingsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(viewModel.changableTabs) { tab in
                        rowForTab(tab)
                    }
                    .onMove(perform: { indices, newOffset in
                        viewModel.moveTabs(indices: indices, newOffset: newOffset)
                    })
                } header: {
                    Text("Drag to reorder")
                } footer: {
                    Text(footerText)
                }

                
                Section {
                    Rectangle()
                        .fill(.clear)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Tabs placements")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .bottom) {
                if viewModel.changedSettingsPosition {
                    Button {
                        viewModel.saveTabs()
                        dismiss()
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
