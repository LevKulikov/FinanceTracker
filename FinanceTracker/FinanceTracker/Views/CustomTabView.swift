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
            viewModel.getSpendIncomeView(namespace: namespace)
                .tag(1)
            
            viewModel.getStatisticsView()
                .tag(2)
            
            viewModel.getSearchView()
                .tag(3)
            
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
        .fullScreenCover(isPresented: $viewModel.isFirstLaunch) {
            viewModel.getWelcomeView()
        }
    }
    
    private var customTabView: some View {
        HStack {
            let buttonWidth: CGFloat = 70
            let imageHeight: CGFloat = 20
            
            Button {
                selectTab(1, animated: true)
            } label: {
                VStack {
                    Image(systemName: "list.bullet.clipboard")
                        .frame(height: imageHeight)
                    
                    Text("List")
                        .font(.caption)
                }
            }
            .frame(width: buttonWidth)
            .foregroundStyle(viewModel.tabSelection == 1 ? .blue : .secondary)
            .hoverEffect(.highlight)
            
            Spacer()
            
            Button {
                selectTab(2)
            } label: {
                VStack {
                    Image(systemName: "chart.bar")
                        .frame(height: imageHeight)
                    
                    Text("Charts")
                        .font(.caption)
                }
            }
            .frame(width: buttonWidth)
            .foregroundStyle(viewModel.tabSelection == 2 ? .blue : .secondary)
            .hoverEffect(.highlight)
            
            if viewModel.tabSelection == 1 {
                Spacer()
                
                Button {
                    viewModel.addButtonPressed()
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
                VStack {
                    Image(systemName: "magnifyingglass")
                        .frame(height: imageHeight)
                    
                    Text("Search")
                        .font(.caption)
                }
            }
            .frame(width: buttonWidth)
            .foregroundStyle(viewModel.tabSelection == 3 ? .blue : .secondary)
            .hoverEffect(.highlight)
            
            Spacer()
            
            Button {
                selectTab(4)
            } label: {
                VStack {
                    Image(systemName: "gear")
                        .frame(height: imageHeight)
                    
                    Text("Setting")
                        .font(.caption)
                }
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
}

#Preview {
    let container = FinanceTrackerApp.createModelContainer()
    let dataManager = DataManager(container: container)
    let viewModel = CustomTabViewModel(dataManager: dataManager)
    
    return CustomTabView(viewModel: viewModel)
}
