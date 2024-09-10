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
    private var availableYOffset: CGFloat {
        if FTAppAssets.currnetUserDeviseName == "iPhone SE (3rd generation)" {
            return 5
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            return 15
        } else {
            return 20
        }
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
            } else {
                viewModel.getSpendIncomeView(namespace: namespace)
                    .tag(1)
            }
            
            if viewModel.isSecondTabCanBeShown {
                viewModel.getSecondTab(namespace: namespace)
                    .tag(2)
            } else {
                viewModel.getStatisticsView()
                    .tag(2)
            }
            
            if viewModel.isThirdTabCanBeShown {
                viewModel.getThirdTab(namespace: namespace)
                    .tag(3)
            } else {
                viewModel.getSearchView()
                    .tag(3)
            }
            
            viewModel.getSettingsView()
                .tag(4)
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
    }
    
    private var customTabView: some View {
        HStack {
            let buttonWidth: CGFloat = 70
            
            Button {
                selectTab(1, animated: true)
            } label: {
                TabViewType.spendIncomeView.tabLabel
            }
            .frame(width: buttonWidth)
            .foregroundStyle(viewModel.tabSelection == 1 ? .blue : .secondary)
            .hoverEffect(.highlight)
            
            Spacer()
            
            Button {
                selectTab(2)
            } label: {
                if viewModel.isSecondTabCanBeShown {
                    viewModel.secondAndThirdTabs[1].tabLabel
                } else {
                    TabViewType.statisticsView.tabLabel
                }
            }
            .frame(width: buttonWidth)
            .foregroundStyle(viewModel.tabSelection == 2 ? .blue : .secondary)
            .hoverEffect(.highlight)
            
            if viewModel.tabSelection == 1 || viewModel.showAddButtonFromEvetyTab {
                Spacer()
                
                Button {
                    addButtonTapped()
                } label: {
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
                .contentShape([.hoverEffect, .contextMenuPreview], Circle())
                .hoverEffect(.highlight)
            }
            
            Spacer()
            
            Button {
                selectTab(3)
            } label: {
                if viewModel.isThirdTabCanBeShown {
                    viewModel.secondAndThirdTabs[2].tabLabel
                } else {
                    TabViewType.searchView.tabLabel
                }
            }
            .frame(width: buttonWidth)
            .foregroundStyle(viewModel.tabSelection == 3 ? .blue : .secondary)
            .hoverEffect(.highlight)
            
            Spacer()
            
            Button {
                selectTab(4)
            } label: {
                TabViewType.settingsView.tabLabel
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
        if viewModel.tabSelection == 1 {
            viewModel.addButtonPressed()
        } else {
            withAnimation {
                actionWithTransaction = .add(.now)
                viewModel.showTabBar = false
            }
        }
    }
}

#Preview {
    let container = FinanceTrackerApp.createModelContainer()
    let dataManager = DataManager(container: container)
    let viewModel = CustomTabViewModel(dataManager: dataManager)
    
    return CustomTabView(viewModel: viewModel)
}
