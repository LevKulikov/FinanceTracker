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
    @State private var tabSelection = 1
    private var availableYOffset: CGFloat {
        if UIDevice.current.name == "iPhone SE (3rd generation)" {
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
        ZStack {
            switch tabSelection {
            case 1:
                viewModel.getSpendIncomeView(namespace: namespace)
                    .tag(1)
            default:
                Label("In develop", systemImage: "gearshape.2")
                    .font(.largeTitle)
                    .tag(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            customTabView
                .offset(y: availableYOffset)
                .opacity(viewModel.showTabBar ? 1 : 0)
        }
    }
    
    private var customTabView: some View {
        HStack {
            let buttonWidth: CGFloat = 70
            let imageHeight: CGFloat = 20
            
            Button {
                selectTab(1)
            } label: {
                VStack {
                    Image(systemName: "list.bullet.clipboard")
                        .frame(height: imageHeight)
                    
                    Text("List")
                        .font(.caption)
                }
            }
            .frame(width: buttonWidth)
            .foregroundStyle(tabSelection == 1 ? .blue : .secondary)
            
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
            .foregroundStyle(tabSelection == 2 ? .blue : .secondary)
            
            if tabSelection == 1 {
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
            }
            
            Spacer()
            
            Button {
                selectTab(3)
            } label: {
                VStack {
                    Image(systemName: "list.bullet.below.rectangle")
                        .frame(height: imageHeight)
                    
                    Text("Entities")
                        .font(.caption)
                }
            }
            .frame(width: buttonWidth)
            .foregroundStyle(tabSelection == 3 ? .blue : .secondary)
            
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
            .foregroundStyle(tabSelection == 4 ? .blue : .secondary)
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
    private func selectTab(_ tabId: Int) {
        withAnimation(.snappy(duration: 0.5)) {
            tabSelection = tabId
        }
    }
}

#Preview {
    let container = FinanceTrackerApp.createModelContainer()
    let dataManager = DataManager(container: container)
    let viewModel = CustomTabViewModel(dataManager: dataManager)
    
    return CustomTabView(viewModel: viewModel)
}
