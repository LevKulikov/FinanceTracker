//
//  CustomTabView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 11.06.2024.
//

import SwiftUI

/// Tag must be Integer
struct CustomTabView<Content>: View where Content: View  {
    @State private var tabSelection = 1
    private var content: () -> Content
    private var availableYOffset: CGFloat {
        if UIDevice.current.name == "iPhone SE (3rd generation)" {
            return 5
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            return 15
        } else {
            return 20
        }
    }
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        TabView(selection: $tabSelection) {
            content()
        }
        .overlay(alignment: .bottom) {
            customTabView
                .offset(y: availableYOffset)
        }
        .ignoresSafeArea(.keyboard)
    }
    
    private var customTabView: some View {
        HStack(alignment: .bottom) {
            let buttonWidth: CGFloat = 70
            
            Button {
                tabSelection = 1
            } label: {
                VStack {
                    Image(systemName: "list.bullet.clipboard")
                    
                    Text("List")
                }
            }
            .frame(width: buttonWidth)
            .foregroundStyle(tabSelection == 1 ? .blue : .secondary)
            
            Spacer()
            
            Button {
                tabSelection = 2
            } label: {
                VStack {
                    Image(systemName: "chart.bar")
                    
                    Text("Charts")
                }
            }
            .frame(width: buttonWidth)
            .foregroundStyle(tabSelection == 2 ? .blue : .secondary)
            
            Spacer()
            
            Button {
                tabSelection = 3
            } label: {
                VStack {
                    Image(systemName: "gear")
                    
                    Text("Settings")
                }
            }
            .frame(width: buttonWidth)
            .foregroundStyle(tabSelection == 3 ? .blue : .secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 15)
        .frame(maxWidth: 500)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
        }
        .padding(.horizontal)
    }
}

#Preview {
    CustomTabView {
        Text("Tab Content 1").tag(1)
        
        Text(UIDevice.current.name).tag(2)
        
        Rectangle()
            .fill(.red)
            .frame(maxHeight: .infinity)
            .tag(3)
    }
}
