//
//  BudgetCard.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 18.07.2024.
//

import SwiftUI
import Charts

struct BudgetCard<MenuItems: View>: View {
    //MARK: - Properties
    private var namespace: Namespace.ID
    private let menuItems: (BudgetCardViewData) -> MenuItems
    @StateObject private var viewModel: BudgetCardViewModel
    private var categoryColor: Color {
        viewModel.budget.category?.color ?? .blue
    }
    private var budgetName: String {
        viewModel.budget.name.isEmpty ? viewModel.budget.category?.name ?? String(localized: "All categories") : viewModel.budget.name
    }
    private var budgetIconName: String {
        viewModel.budget.category?.iconName ?? ""
    }
    private var budgetCurrency: String {
        viewModel.budget.balanceAccount?.currency ?? ""
    }
    private var isBudgetOver: Bool {
        viewModel.totalValue > viewModel.budget.value
    }
    
    //MARK: - Initializer
    init(viewModel: BudgetCardViewModel, namespace: Namespace.ID, @ViewBuilder menuItems: @escaping (BudgetCardViewData) -> MenuItems) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.namespace = namespace
        self.menuItems = menuItems
    }
    
    //MARK: - Body
    var body: some View {
        Menu {
            menuItems(viewModel.getBudgetCardData())
        } label: {
            VStack {
                HStack {
                    if viewModel.budget.category != nil {
                        FTAppAssets.iconImageOrEpty(name: budgetIconName)
                            .scaledToFit()
                            .foregroundStyle(categoryColor)
                            .matchedGeometryEffect(id: "budgetIcon" + viewModel.budget.id, in: namespace)
                            .frame(width: 30, height: 30)
                    }
                    
                    Text(budgetName)
                        .matchedGeometryEffect(id: "budgetName" + viewModel.budget.id, in: namespace)
                        .bold()
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if viewModel.isProcessing {
                        ProgressView()
                    }
                    
                    Spacer()
                    
                    Text(viewModel.budget.period.localizedString)
                        .foregroundStyle(.secondary)
                        .layoutPriority(1)
                        .matchedGeometryEffect(id: "budgetPeriod" + viewModel.budget.id, in: namespace)
                }
                .frame(minHeight: 30)
                
                lineChart
                    .padding(.vertical, 7)
                    .matchedGeometryEffect(id: "budgetChart" + viewModel.budget.id, in: namespace)
                
                HStack {
                    Text(FTFormatters.numberFormatterWithDecimals.string(for: viewModel.totalValue) ?? "Err")
                        .foregroundStyle(isBudgetOver ? Color.red : Color.primary)
                        .matchedGeometryEffect(id: "budgetTotal" + viewModel.budget.id, in: namespace)
                    Text(budgetCurrency)
                        .foregroundStyle(isBudgetOver ? Color.red : Color.primary)
                        .matchedGeometryEffect(id: "budgetCurrecyTotal" + viewModel.budget.id, in: namespace)
                    
                    Spacer()
                    
                    Text(FTFormatters.numberFormatterWithDecimals.string(for: viewModel.budget.value) ?? "Err")
                        .layoutPriority(1)
                        .matchedGeometryEffect(id: "budgetValue" + viewModel.budget.id, in: namespace)
                    Text(budgetCurrency)
                        .layoutPriority(1)
                        .matchedGeometryEffect(id: "budgetCurrecyValue" + viewModel.budget.id, in: namespace)
                }
                .font(.subheadline)
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemBackground))
                    .matchedGeometryEffect(id: "budgetBachround" + viewModel.budget.id, in: namespace)
            }
        }
        .foregroundStyle(.primary)
        .onChange(of: viewModel.budget.category) {
            viewModel.fetchAndCalculate()
        }
    }
    
    //MARK: - Computed View Properties
    private var lineChart: some View {
        Chart {
            BarMark(
                x: .value("Budget total", viewModel.totalValue),
                y: .value("Budget name", viewModel.budget.name)
            )
            .foregroundStyle(categoryColor)
            .cornerRadius(10)
        }
        .chartLegend(.hidden)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 10)
        .chartXScale(domain: 0...viewModel.budget.value)
        .mask {
            Capsule()
                .frame(height: 7)
        }
        .background {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(height: 7)
        }
    }
    
    //MARK: - Methods
    
}

#Preview {
    let dataManager = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = BudgetCardViewModel(dataManager: dataManager, budget: .empty)
    @Namespace var namespace
    @State var flag = false
    
    return BudgetCard(viewModel: viewModel, namespace: namespace) { _ in
        EmptyView()
    }
}
