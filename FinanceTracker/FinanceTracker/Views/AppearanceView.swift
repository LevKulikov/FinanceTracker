//
//  AppearanceView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 25.06.2024.
//

import SwiftUI

struct AppearanceView: View {
    //MARK: - Properties
    @StateObject private var viewModel: AppearanceViewModel
    private var showAddButtonSectionFooterText: LocalizedStringResource {
        if viewModel.showAddButtonFromEvetyTab {
            return "The Add Transaction button is currently displayed on every tab, so you can add a transaction at any time"
        }
        
        return "The Add Transaction button is only displayed when you tap the \"List\" tab."
    }
    
    //MARK: - Initializer
    init(viewModel: AppearanceViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Always show add transaction button", isOn: $viewModel.showAddButtonFromEvetyTab)
                } header: {
                    Text("Large blue circle button with plus")
                } footer: {
                    Text(showAddButtonSectionFooterText)
                }
                
                getRowFor(colorScheme: nil, title: "System mode")
                
                getRowFor(colorScheme: .light, title: "Light mode")
                
                getRowFor(colorScheme: .dark, title: "Dark mode")
            }
            .navigationTitle("Appearance")
        }
    }
    
    //MARK: - Computed view props
    
    
    //MARK: - Methods
    @ViewBuilder
    private func getRowFor(colorScheme: ColorScheme?, title: LocalizedStringResource) -> some View {
        HStack {
            Text(title)
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(.gray)
                    .fill(viewModel.preferredColorScheme == colorScheme ? .blue : .clear)
                
                if viewModel.preferredColorScheme == colorScheme {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.white)
                        .fontWeight(.medium)
                }
            }
            .frame(width: 27, height: 27)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard viewModel.preferredColorScheme != colorScheme else { return }
            viewModel.setPreferredColorScheme(colorScheme)
        }
    }
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = AppearanceViewModel(dataManager: dataManger)
    
    return AppearanceView(viewModel: viewModel)
}
