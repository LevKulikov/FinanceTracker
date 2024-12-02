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
    @Environment(\.colorScheme) private var colorScheme
    @State private var showAddingFilterView: Bool = false
    @State private var updatedConfiguration: SearchConfiguration?
    private let userDevice = FTAppAssets.currentUserDevise
    private var isIpad: Bool {
        FTAppAssets.currentUserDevise == .pad
    }
    
    //MARK: - Initializer
    init(viewModel: AdvancedAnalyticsViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    //MARK: - Computed View Properties
    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.searchConfigurations.isEmpty {
                    noFilterAddedView
                }
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 130))]) {
                    ForEach(viewModel.searchConfigurations) { config in
                        ConfigurationCell(config)
                    }
                }
                .padding(.horizontal, 10)
                
                Rectangle()
                    .fill(.clear)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .navigationTitle("Advanced Analytics")
            .toolbar {
                if viewModel.isLoadingOtherData {
                    ProgressView()
                } else {
                    Button("Add filter", systemImage: "plus") {
                        showAddingFilterView.toggle()
                    }
                    .labelStyle(.iconOnly)
                    .disabled(viewModel.isLoadingTransactions)
                }
            }
            .overlay(alignment: .bottom) {
                if !viewModel.searchConfigurations.isEmpty {
                    analyticsButton
                        .offset(y: userDevice == .phone ? 0 : -60)
                }
            }
            .overlay {
                if viewModel.isLoadingTransactions {
                    transactionsLoadingView
                }
            }
            .onAppear {
                viewModel.fetchOtherData()
            }
            .sheet(isPresented: $showAddingFilterView) {
                AddUpdateSearchConfigurationView(configuration: nil, balanceAccounts: viewModel.allBalanceAccounts, categories: viewModel.allCategories, tags: viewModel.allTags) { config in
                    viewModel.addConfiguration(config)
                    showAddingFilterView.toggle()
                }
            }
            .sheet(item: $updatedConfiguration) { config in
                AddUpdateSearchConfigurationView(configuration: config, balanceAccounts: viewModel.allBalanceAccounts, categories: viewModel.allCategories, tags: viewModel.allTags) { configuration in
                    viewModel.updateConfiguration(configuration)
                    updatedConfiguration = nil
                }
            }
            .sheet(isPresented: $viewModel.showAnalytics) {
                viewModel.getAnalyticsPage()
            }
        }
    }
    
    private var noFilterAddedView: some View {
        ContentUnavailableView {
            Label("No filters added", systemImage: "tray")
        } description: {
            Text("Add any number of filters to search for transactions of interest and get analytics on them. Analytics will reflect unique transactions")
        } actions: {
            Button("Add filter") {
                showAddingFilterView.toggle()
            }
            .buttonStyle(.bordered)
        }
    }
    
    private var analyticsButton: some View {
        Button {
            viewModel.getAnalytics()
        } label: {
            Label("Get analytics", systemImage: "chart.bar")
                .frame(width: 170, height: 50)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .stroke(.blue)
                }
        }
        .offset(y: -5)
    }
    
    private var transactionsLoadingView: some View {
        VStack {
            ProgressView()
                .controlSize(.large)
            Text("Loading...")
                .foregroundStyle(.secondary)
                .padding(.bottom)
                .padding(.bottom)
            
            Button("Cancel") {
                viewModel.cancelFetching()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: 200, maxHeight: 200)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(colorScheme == .light ? Color(.systemBackground) : Color(.systemGray6))
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        }
        .animation(.default, value: viewModel.isLoadingTransactions)
    }
    
    //MARK: - Methods
    @ViewBuilder
    private func ConfigurationCell(_ configuration: SearchConfiguration) -> some View {
        VStack {
            Text(configuration.filterTransactionType.rawValue)
            Text(configuration.dateFilterType.rawValue)
            Text(configuration.filterBalanceAccount?.name ?? "All accounts")
            Text(configuration.filterCategory?.name ?? "All categories")
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.5))
        }
        .onTapGesture {
            updatedConfiguration = configuration
        }
    }
}

#Preview {
    let dataManager = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = AdvancedAnalyticsViewModel(dataManager: dataManager)
    AdvancedAnalyticsView(viewModel: viewModel)
}
