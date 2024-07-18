//
//  BudgetCard.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 18.07.2024.
//

import SwiftUI
import Charts

struct BudgetCard: View {
    //MARK: - Properties
    var namespace: Namespace.ID
    @StateObject private var viewModel: BudgetCardViewModel
    private var categoryColor: Color {
        viewModel.budget.category?.color ?? .clear
    }
    private var budgetName: String {
        viewModel.budget.name.isEmpty ? viewModel.budget.category?.name ?? "Empty" : viewModel.budget.name
    }
    private var budgetIconName: String {
        viewModel.budget.category?.iconName ?? ""
    }
    private var budgetCurrency: String {
        viewModel.budget.balanceAccount?.currency ?? ""
    }
    
    //MARK: - Initializer
    init(viewModel: BudgetCardViewModel, namespace: Namespace.ID) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.namespace = namespace
    }
    
    //MARK: - Body
    var body: some View {
        VStack {
            HStack {
                FTAppAssets.iconImageOrEpty(name: budgetIconName)
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(Color.orange)
                
                Text(budgetName)
                    .bold()
                
                Spacer()
                
                Text(viewModel.budget.period.localizedString)
                    .foregroundStyle(.secondary)
                    .layoutPriority(1)
            }
            .padding(.horizontal)
            
            lineChart
                .padding(.horizontal)
                .padding(.vertical, 7)
            
            HStack {
                Text(FTFormatters.numberFormatterWithDecimals.string(for: viewModel.totalValue) ?? "Err")
                Text(budgetCurrency)
                
                Spacer()
                
                Text(FTFormatters.numberFormatterWithDecimals.string(for: viewModel.budget.value) ?? "Err")
                    .layoutPriority(1)
                Text(budgetCurrency)
                    .layoutPriority(1)
            }
            .font(.subheadline)
            .padding(.horizontal)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
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
    
    return BudgetCard(viewModel: viewModel, namespace: namespace)
}
