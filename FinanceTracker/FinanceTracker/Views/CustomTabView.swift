//
//  CustomTabView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 11.06.2024.
//

import SwiftUI

/// Tag must be Integer
struct CustomTabView: View  {
    //MARK: - Propeties
    @Namespace private var namespace
    @StateObject private var viewModel: CustomTabViewModel
    @State private var actionWithTransaction: ActionWithTransaction = .none
    @State private var windowSize: CGSize = FTAppAssets.getWindowSize()
    private var availableYOffset: CGFloat {
        if FTAppAssets.currnetUserDeviseName == "iPhone SE (3rd generation)" {
            return 5
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            return 15
        } else {
            return 20
        }
    }
    private var showAddButton: Bool {
        isSpendIncomeView(tab: viewModel.tabSelection) || viewModel.showAddButtonFromEvetyTab || !viewModel.firstThreeTabs.contains(.spendIncomeView)
    }
    private var showNewIpadTabView: Bool {
        let iosVersion = ProcessInfo.processInfo.operatingSystemVersion.majorVersion
        return windowSize.width > 660 && iosVersion >= 18 && FTAppAssets.currentUserDevise == .pad
    }
    
    //MARK: - Init
    init(viewModel: CustomTabViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        TabView(selection: $viewModel.tabSelection) {
            if viewModel.isFirstTabCanBeShown {
                viewModel.getFirstTab(namespace: namespace)
                    .tag(1)
                    .tabItem {
                        labelForTab(1, customLabel: false)
                    }
            } else {
                viewModel.getSpendIncomeView(namespace: namespace)
                    .tag(1)
                    .tabItem {
                        labelForTab(1, customLabel: false)
                    }
            }
            
            if viewModel.isSecondTabCanBeShown {
                viewModel.getSecondTab(namespace: namespace)
                    .tag(2)
                    .tabItem {
                        labelForTab(2, customLabel: false)
                    }
            } else {
                viewModel.getStatisticsView()
                    .tag(2)
                    .tabItem {
                        labelForTab(2, customLabel: false)
                    }
            }
            
            if viewModel.isThirdTabCanBeShown {
                viewModel.getThirdTab(namespace: namespace)
                    .tag(3)
                    .tabItem {
                        labelForTab(3, customLabel: false)
                    }
            } else {
                viewModel.getSearchView()
                    .tag(3)
                    .tabItem {
                        labelForTab(3, customLabel: false)
                    }
            }
            
            if viewModel.isForthTabCanBeShown {
                viewModel.getForthTab(namespace: namespace)
                    .tag(4)
                    .tabItem {
                        labelForTab(4, customLabel: false)
                    }
            } else {
                viewModel.getSettingsView()
                    .tag(4)
                    .tabItem {
                        labelForTab(4, customLabel: false)
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            customTabView
                .offset(y: availableYOffset)
                .disabled(!viewModel.showTabBar)
                .opacity(viewModel.showTabBar ? 1 : 0)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .overlay {
            if case .add = actionWithTransaction {
                viewModel.getAddingSpendIncomeView(forAction: $actionWithTransaction, namespace: namespace)
            } else if case .update = actionWithTransaction  {
                viewModel.getAddingSpendIncomeView(forAction: $actionWithTransaction, namespace: namespace)
            }
        }
        .fullScreenCover(isPresented: $viewModel.isFirstLaunch) {
            viewModel.getWelcomeView()
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newValue in
            windowSize = newValue
        }
    }
    
    @ViewBuilder
    private var customTabView: some View {
        if showNewIpadTabView {
            HStack {
                if showAddButton {
                    addButton
                }
            }
            .padding(.vertical, 15)
            .onChange(of: actionWithTransaction) {
                if case .none = actionWithTransaction {
                    viewModel.showTabBar = true
                }
            }
        } else {
            HStack {
                let buttonWidth: CGFloat = 70
                
                Button {
                    selectTab(1, animated: isSpendIncomeView(tab: 1))
                } label: {
                    labelForTab(1)
                }
                .frame(width: buttonWidth)
                .foregroundStyle(viewModel.tabSelection == 1 ? .blue : .secondary)
                .hoverEffect(.highlight)
                
                Spacer()
                
                Button {
                    selectTab(2, animated: isSpendIncomeView(tab: 2))
                } label: {
                    labelForTab(2)
                }
                .frame(width: buttonWidth)
                .foregroundStyle(viewModel.tabSelection == 2 ? .blue : .secondary)
                .hoverEffect(.highlight)
                
                if showAddButton {
                    Spacer()
                    
                    addButton
                }
                
                Spacer()
                
                Button {
                    selectTab(3, animated: isSpendIncomeView(tab: 3))
                } label: {
                    labelForTab(3)
                }
                .frame(width: buttonWidth)
                .foregroundStyle(viewModel.tabSelection == 3 ? .blue : .secondary)
                .hoverEffect(.highlight)
                
                Spacer()
                
                Button {
                    selectTab(4, animated: isSpendIncomeView(tab: 4))
                } label: {
                    labelForTab(4)
                }
                .frame(width: buttonWidth)
                .foregroundStyle(viewModel.tabSelection == 4 ? .blue : .secondary)
                .hoverEffect(.highlight)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 15)
            .frame(maxWidth: 500)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
            }
            .padding(.horizontal)
            .onChange(of: actionWithTransaction) {
                if case .none = actionWithTransaction {
                    viewModel.showTabBar = true
                }
            }
        }
    }
    
    private var addButton: some View {
        Button {
            addButtonTapped()
        } label: {
            if showNewIpadTabView {
                Label("Add transaction", systemImage: "plus")
                    .frame(height: 50)
                    .frame(minWidth: 170)
                    .padding(.horizontal, 16)
                    .foregroundStyle(.white)
                    .background {
                        Capsule()
                            .fill(.blue)
                            .matchedGeometryEffect(id: "buttonBackground", in: namespace)
                    }
            } else {
                ZStack {
                    Circle()
                        .fill(.blue)
                        .matchedGeometryEffect(id: "buttonBackground", in: namespace)
                        .frame(width: 50)
                    
                    Image(systemName: "plus")
                        .font(.title)
                        .foregroundStyle(.white)
                }
            }
        }
        .contentShape([.hoverEffect, .contextMenuPreview], Circle())
        .hoverEffect(.highlight)
    }
    
    //MARK: - Methods
    private func selectTab(_ tabId: Int, animated: Bool = false) {
        guard viewModel.tabSelection != tabId else { return }
        if animated {
            withAnimation {
                viewModel.tabSelection = tabId
            }
        } else {
            viewModel.tabSelection = tabId
        }
    }
    
    private func addButtonTapped() {
        if isSpendIncomeView(tab: viewModel.tabSelection) {
            viewModel.addButtonPressed()
        } else {
            withAnimation {
                actionWithTransaction = .add(.now)
                viewModel.showTabBar = false
            }
        }
    }
    
    /// Tabs count starts from 1
    private func isSpendIncomeView(tab: Int) -> Bool {
        guard viewModel.firstThreeTabs.count > (tab - 1) else { return false }
        return viewModel.firstThreeTabs[tab - 1] == .spendIncomeView
    }
    
    @ViewBuilder
    private func labelForTab(_ tabNumber: Int, customLabel: Bool = true) -> some View {
        switch tabNumber {
        case 1:
            if viewModel.isFirstTabCanBeShown {
                if customLabel {
                    viewModel.firstThreeTabs[0].tabLabel
                } else {
                    viewModel.firstThreeTabs[0].label
                }
            } else {
                if customLabel {
                    TabViewType.spendIncomeView.tabLabel
                } else {
                    TabViewType.spendIncomeView.label
                }
            }
        case 2:
            if viewModel.isSecondTabCanBeShown {
                if customLabel {
                    viewModel.firstThreeTabs[1].tabLabel
                } else {
                    viewModel.firstThreeTabs[1].label
                }
            } else {
                if customLabel {
                    TabViewType.statisticsView.tabLabel
                } else {
                    TabViewType.statisticsView.label
                }
            }
        case 3:
            if viewModel.isThirdTabCanBeShown {
                if customLabel {
                    viewModel.firstThreeTabs[2].tabLabel
                } else {
                    viewModel.firstThreeTabs[2].label
                }
            } else {
                if customLabel {
                    TabViewType.searchView.tabLabel
                } else {
                    TabViewType.searchView.label
                }
            }
        case 4:
            if viewModel.isForthTabCanBeShown {
                if customLabel {
                    viewModel.firstThreeTabs[3].tabLabel
                } else {
                    viewModel.firstThreeTabs[3].label
                }
            } else {
                if customLabel {
                    TabViewType.settingsView.tabLabel
                } else {
                    TabViewType.settingsView.label
                }
            }
        default:
            EmptyView()
        }
    }
}

#Preview {
    let container = FinanceTrackerApp.createModelContainer()
    let dataManager = DataManager(container: container)
    let viewModel = CustomTabViewModel(dataManager: dataManager)
    
    return CustomTabView(viewModel: viewModel)
}
