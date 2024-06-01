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
                    ForEach(viewModel.transactions) { transaction in
                        SpendIncomeCell(transaction: transaction, namespace: namespace)
                            .onTapGesture {
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
            guard tapEnabled else { return }
            tapEnabled = false
            withAnimation(.snappy(duration: 0.5)) {
                actionSelected = .add
            }
        } label: {
            Label("Add \(viewModel.transactionsTypeSelected == .spending ? "spending" : "income")", systemImage: "plus")
                .background {
                    Capsule()
                        .fill(.thinMaterial)
                        .matchedGeometryEffect(id: "buttonBackground", in: namespace)
                        .padding(.horizontal, -30)
                        .padding(.vertical, -15)
                }
        }
        .offset(y: -20)
        .contextMenu {
            Button("Add test transaction") {
                createTestTransaction()
            }
        }
    }
    
    //MARK: Methods
    private func createTestTransaction() {
        viewModel.insert(
            Transaction(
                type: viewModel.transactionsTypeSelected,
                comment: "",
                value: 123_200,
                date: Date.now,
                balanceAccount: BalanceAccount(name: "Test My", currency: "RUB", balance: 100_000, iconName: "testIcon", color: .yellow),
                category: Category(type: viewModel.transactionsTypeSelected, name: "Another Test Cat", iconName: "testIcon",
                                   color: viewModel.transactionsTypeSelected == .spending ? .red : .green),
                tags: [Tag(name: "first"),Tag(name: "second"),Tag(name: "third"),Tag(name: "foobartaglong"),]
            )
        )
    }
    
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