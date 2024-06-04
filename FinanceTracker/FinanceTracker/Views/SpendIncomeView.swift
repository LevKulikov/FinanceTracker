//
//  SpendIncomeView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 25.05.2024.
//

import SwiftUI

enum ActionWithTransaction: Equatable {
    case none
    case add
    case update(Transaction)
}

struct SpendIncomeView: View {
    //MARK: Properties
    @Namespace private var namespace
    @StateObject private var viewModel: SpendIncomeViewModel
    @State private var actionSelected: ActionWithTransaction = .none
    @State private var transactionIdSelected: String = ""
    @State private var tapEnabled = true
    
    //MARK: Init
    init(viewModel: SpendIncomeViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: Computed View props
    var body: some View {
        ZStack {
            ScrollView {
                VStack {
                    ForEach(viewModel.transactions, id: \.self) { transactionArray in
                        GroupedSpendIncomeCell(transactions: transactionArray, namespace: namespace) { transaction in
                            guard tapEnabled else { return }
                            tapEnabled = false
                            transactionIdSelected = transaction.id
                            withAnimation(.snappy(duration: 0.5)) {
                                actionSelected = .update(transaction)
                            }
                            
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
            .onChange(of: actionSelected) {
                if case .none = actionSelected {
                    viewModel.fetchTransactions()
                    enableTapsWithDeadline()
                }
            }
            
            if case .add = actionSelected {
                viewModel.getAddUpdateView(forAction: $actionSelected, namespace: namespace)
            } else if case .update(_) = actionSelected {
                viewModel.getAddUpdateView(forAction: $actionSelected, namespace: namespace)
            }
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
                    .matchedGeometryEffect(id: "picker", in: namespace)
                    .scaleEffect(scaleProgress, anchor: .top)
                    .scaleEffect(reversedScaleProgress, anchor: .top)
                    .offset(y: yOffset)
                    .frame(maxWidth: .infinity)
                
                Spacer()
            }
        }
        .frame(height: 70)
    }
    
    private var addButton: some View {
        Button {
            guard tapEnabled else { return }
            tapEnabled = false
            withAnimation(.snappy(duration: 0.5)) {
                actionSelected = .add
            }
        } label: {
            Label("Add \(viewModel.transactionsTypeSelected == .spending ? "spending" : "income")", systemImage: "plus")
                .frame(width: 200, height: 55)
                .background {
                    Capsule()
                        .fill(.thinMaterial)
                        .matchedGeometryEffect(id: "buttonBackground", in: namespace)
                }
        }
        .offset(y: -5)
    }
    
    //MARK: Methods
    private func deleteTransaction(_ transaction: Transaction) {
        viewModel.delete(transaction)
    }
    
    private func enableTapsWithDeadline() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            tapEnabled = true
        }
    }
}

#Preview {
    let container = FinanceTrackerApp.createModelContainer()
    let dataManager = DataManager(container: container)
    let viewModel = SpendIncomeViewModel(dataManager: dataManager)
    
    return SpendIncomeView(viewModel: viewModel)
}
