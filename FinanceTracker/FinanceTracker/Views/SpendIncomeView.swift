//
//  SpendIncomeView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 25.05.2024.
//

import SwiftUI

struct SpendIncomeView: View {
    //MARK: Properties
    @Namespace private var namespace
    @StateObject private var viewModel: SpendIncomeViewModel
    
    //MARK: Init
    init(viewModel: SpendIncomeViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: Computed View props
    var body: some View {
        ScrollView {
            VStack {
                ForEach(0..<20) { index in
                    Rectangle()
                        .fill(viewModel.transactionsTypeSelected == .spending ? .red : .green)
                        .frame(width: 350, height: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
                        .onTapGesture {
                            print("Tap rect \(index)")
                        }
                }
                
                Rectangle()
                    .fill(.clear)
                    .frame(height: 40)
            }
            .safeAreaInset(edge: .top) {
                spendIncomePicker
            }
            
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .bottom) {
            addButton
        }
    }
    
    @ViewBuilder
    private var spendIncomePicker: some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
            let scrollViewHeight = proxy.bounds(of: .scrollView(axis: .vertical))?.height ?? 0
            let scaleProgress = minY > 0 ? 1 + max(min(minY / scrollViewHeight, 1), 0) * 0.5 : 1
            let reversedScaleProgress = minY < 0 ? max(((scrollViewHeight + minY) / scrollViewHeight), 0.8) : 1
            let yOffset = minY < 0 ? -minY + max((minY / 5), -5) : 0
            
            HStack {
                Spacer()
                
                SpendIncomePicker(transactionsTypeSelected: $viewModel.transactionsTypeSelected)
                    .scaleEffect(scaleProgress, anchor: .top)
                    .scaleEffect(reversedScaleProgress, anchor: .top)
                    .offset(y: yOffset)
                    .frame(maxWidth: .infinity)
//                    .background {
//                        Rectangle()
//                            .fill(Material.ultraThin)
//                            .padding(.bottom, -6)
//                            .padding(.top, -100)
//                            .padding(.horizontal, -20)
//                            .offset(y:  yOffset)
//                            .opacity(minY >= 0 ? 0 : min(((-minY / scrollViewHeight) * (scrollViewHeight / 50)), 1))
//                    }
                
                Spacer()
            }
        }
        .frame(height: 70)
    }
    
    @ViewBuilder
    private var addButton: some View {
        Button {
            
        } label: {
            Label("Add \(viewModel.transactionsTypeSelected == .spending ? "spending" : "income")", systemImage: "plus")
                .background {
                    Capsule()
                        .fill(.thinMaterial)
                        .padding(.horizontal, -30)
                        .padding(.vertical, -15)
                }
        }
    }
    
    //MARK: Methods
}

#Preview {
    let container = FinanceTrackerApp.createModelContainer()
    let dataManager = DataManager(container: container)
    let viewModel = SpendIncomeViewModel(dataManager: dataManager)
    
    return SpendIncomeView(viewModel: viewModel)
}
