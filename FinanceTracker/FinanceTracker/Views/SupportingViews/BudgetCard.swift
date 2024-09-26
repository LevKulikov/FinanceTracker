//
//  BudgetCard.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 18.07.2024.
//

import SwiftUI
import Charts

enum BudgetCardType: Equatable {
    case line
    case pie
}

struct BudgetCard<MenuItems: View>: View {
    //MARK: - Properties
    @Environment(\.colorScheme) var colorScheme
    private var namespace: Namespace.ID
    private let type: BudgetCardType
    private let menuItems: (BudgetCardViewData) -> MenuItems
    @StateObject private var viewModel: BudgetCardViewModel
    @State private var currency: Currency?
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
        currency?.symbol ?? (viewModel.budget.balanceAccount?.currency ?? "")
    }
    private var isBudgetOver: Bool {
        viewModel.totalValue > viewModel.budget.value
    }
    private var backgroundColor: Color {
        colorScheme == .light ? Color(.systemBackground) : Color(.secondarySystemBackground)
    }
    
    //MARK: - Initializer
    init(viewModel: BudgetCardViewModel, namespace: Namespace.ID, type: BudgetCardType, @ViewBuilder menuItems: @escaping (BudgetCardViewData) -> MenuItems) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.namespace = namespace
        self.type = type
        self.menuItems = menuItems
    }
    
    init(dataManager: some DataManagerProtocol, namespace: Namespace.ID, type: BudgetCardType, budgetData: BudgetCardViewData) where MenuItems == EmptyView {
        self._viewModel = StateObject(wrappedValue: BudgetCardViewModel(dataManager: dataManager, budget: budgetData.budget, transactions: budgetData.transactions))
        self.namespace = namespace
        self.type = type
        self.menuItems = { _ in EmptyView() }
    }
    
    //MARK: - Body
    var body: some View {
        Menu {
            menuItems(viewModel.getBudgetCardData())
        } label: {
            switch type {
            case .line:
                cardWithLine
            case .pie:
                cardWithPie
            }
        }
        .foregroundStyle(.primary)
        .onChange(of: viewModel.budget.category) {
            viewModel.fetchAndCalculate()
        }
        .task {
            guard currency == nil else { return }
            if let codeString = viewModel.budget.balanceAccount?.currency {
                currency = await FTAppAssets.getCurrency(for: codeString)
            }
        }
    }
    
    //MARK: - Computed View Properties
    private var cardWithPie: some View {
        HStack {
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
                }
                
                Spacer()
                
                HStack {
                    Text(FTFormatters.numberFormatterWithDecimals.string(for: viewModel.budget.value) ?? "Err")
                        .matchedGeometryEffect(id: "budgetValue" + viewModel.budget.id, in: namespace)
                    Text(budgetCurrency)
                        .matchedGeometryEffect(id: "budgetCurrecyValue" + viewModel.budget.id, in: namespace)
                    
                    Spacer()
                }
                .lineLimit(1)
                .font(.subheadline)
                
                HStack {
                    Text("Spent")
                        .foregroundStyle(.secondary)
                    
                    Text(FTFormatters.numberFormatterWithDecimals.string(for: viewModel.totalValue) ?? "Err")
                        .foregroundStyle(isBudgetOver ? Color.red : Color.primary)
                        .layoutPriority(1)
                        .matchedGeometryEffect(id: "budgetTotal" + viewModel.budget.id, in: namespace)
                    Text(budgetCurrency)
                        .foregroundStyle(isBudgetOver ? Color.red : Color.primary)
                        .layoutPriority(1)
                        .matchedGeometryEffect(id: "budgetCurrecyTotal" + viewModel.budget.id, in: namespace)
                    
                    Spacer()
                }
                .lineLimit(1)
                .font(.subheadline)
            }
            
            pieChart
                .matchedGeometryEffect(id: "budgetChart" + viewModel.budget.id, in: namespace)
                .overlay {
                    Text(viewModel.budget.period.localizedString)
                        .foregroundStyle(.secondary)
                        .matchedGeometryEffect(id: "budgetPeriod" + viewModel.budget.id, in: namespace)
                }
                .padding(.leading)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(backgroundColor)
                .matchedGeometryEffect(id: "budgetBachround" + viewModel.budget.id, in: namespace)
        }
    }
    
    private var cardWithLine: some View {
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
                .fill(backgroundColor)
                .matchedGeometryEffect(id: "budgetBachround" + viewModel.budget.id, in: namespace)
        }
    }
    
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
    
    private var pieChart: some View {
        Chart {
            SectorMark(
                angle: .value("Budget total", viewModel.totalValue),
                innerRadius: .ratio(0.7)
            )
            .foregroundStyle(categoryColor)
            
            if (viewModel.budget.value - viewModel.totalValue) > 0 {
                SectorMark(
                    angle: .value("Budget", (viewModel.budget.value - viewModel.totalValue)),
                    innerRadius: .ratio(0.7)
                )
                .foregroundStyle(Color(.systemGray4))
            }
        }
        .chartLegend(.hidden)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(width: 100, height: 100)
    }
    
    //MARK: - Methods
    
}

#Preview {
    @Previewable @Namespace var namespace
    @Previewable @State var flag = false
    let dataManager = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = BudgetCardViewModel(dataManager: dataManager, budget: .empty)
    
    return BudgetCard(viewModel: viewModel, namespace: namespace, type: .line) { _ in
        EmptyView()
    }
}
