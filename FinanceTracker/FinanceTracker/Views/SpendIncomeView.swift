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
                ForEach(viewModel.transactions) { transaction in
                    SpendIncomeCell(transaction: transaction)
                        .onTapGesture {
                            deleteTransaction(transaction)
                        }
                        .scrollTransition { content, phase in
                            content
                                .offset(y: phase.isIdentity ? 0 : phase == .topLeading ? 100 : -100)
                                .scaleEffect(phase.isIdentity ? 1 : 0.7)
                                .opacity(phase.isIdentity ? 1 : 0)
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
            createTestTransaction()
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
    private func createTestTransaction() {
        viewModel.insert(
            Transaction(
                type: viewModel.transactionsTypeSelected,
                comment: "",
                value: 100000,
                date: Date.now,
                balanceAccount: BalanceAccount(name: "Test BalanceAccount", currency: "RUB", balance: 100_000, iconName: "testIcon", color: .yellow),
                category: Category(type: viewModel.transactionsTypeSelected, name: "Test Cat", iconName: "testIcon", 
                                   color: viewModel.transactionsTypeSelected == .spending ? .red : .green),
                tags: []
            )
        )
    }
    
    private func deleteTransaction(_ transaction: Transaction) {
        viewModel.delete(transaction)
    }
}

#Preview {
    let container = FinanceTrackerApp.createModelContainer()
    let dataManager = DataManager(container: container)
    let viewModel = SpendIncomeViewModel(dataManager: dataManager)
    
    return SpendIncomeView(viewModel: viewModel)
}
