//
//  TransactionPieChart.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 13.06.2024.
//

import SwiftUI
import Charts

struct TransactionPieChartData: Identifiable {
    let id = UUID().uuidString
    let category: Category
    let sumValue: Float
    let transactions: [Transaction]
}

struct TransactionPieChart: View {
    //MARK: - Properties
    private let transactionsChartData: [TransactionPieChartData]
    private let onCategoryDataTap: (TransactionPieChartData) -> Void
    private var sumOfValue: Float = 0
    @State private var selectedValue: Int?
    @State private var selectedCategoryId: String?
    @State private var cancleDispatchWorkItem: DispatchWorkItem?
    private var selectedCategoryPersentage: Int? {
        guard let selectedCategoryId else { return nil }
        guard let data = transactionsChartData.first(where: { $0.category.id == selectedCategoryId }) else { return nil }
        return calculatePercentage(for: data.sumValue)
    }
    private var selectedCategoryValue: Float? {
        guard let selectedCategoryId else { return nil }
        guard let data = transactionsChartData.first(where: { $0.category.id == selectedCategoryId }) else { return nil }
        return data.sumValue
    }
    
    //MARK: - Init
    init(transactionGroups: [TransactionPieChartData], onTap: @escaping (TransactionPieChartData) -> Void) {
        self.transactionsChartData = transactionGroups
        self.onCategoryDataTap = onTap
        sumOfValue = calculateTotalValue()
    }
    
    //MARK: - Body
    var body: some View {
        HStack {
            Chart {
                if !transactionsChartData.isEmpty {
                    ForEach(transactionsChartData) { singleData in
                        let selectedFlag = isSelected(singleData.category)
                        
                        SectorMark(
                            angle: .value("Sum of transactions", singleData.sumValue),
                            innerRadius: .ratio(0.65),
                            outerRadius: .ratio(selectedFlag ? 1 : 0.95),
                            angularInset: selectedFlag ? 1.5 : 0
                        )
                        .cornerRadius(selectedFlag ? 3 : 0)
                        .foregroundStyle(singleData.category.color)
                        .opacity(
                            selectedCategoryId != nil ? (selectedFlag ? 1 : 0.6) : 1
                        )
                        .foregroundStyle(by: .value(Text(verbatim: singleData.category.name), singleData.category.name))
                    }
                } else {
                    SectorMark(
                        angle: .value("Empy", 100),
                        innerRadius: .ratio(0.65),
                        outerRadius: .ratio(0.95)
                    )
                    .foregroundStyle(Color.gray.opacity(0.5))
                }
            }
            .chartAngleSelection(value: $selectedValue)
            .chartLegend(.hidden)
            .onChange(of: selectedValue, setSelectedCategoryId)
            .overlay { chartOverlay }
            
            charLegendView
        }
    }
    
    private var charLegendView: some View {
        ScrollViewReader { proxy in 
            ScrollView {
                VStack(alignment: .leading) {
                    if !transactionsChartData.isEmpty {
                        ForEach(transactionsChartData) {singleData in
                            let selectedFlag = isSelected(singleData.category)
                            
                            HStack {
                                BasicChartSymbolShape.circle
                                    .foregroundStyle(singleData.category.color)
                                    .frame(width: 8, height: 8)
                                
                                Text(singleData.category.name)
                                    .foregroundColor(selectedFlag ? .primary : .gray)
                                    .font(.caption)
                            }
                            .underline(selectedFlag, color: .secondary)
                            .onTapGesture {
                                setSelectedCategory(selectedFlag ? nil : singleData.category)
                            }
                            .contentShape([.contextMenuPreview, .hoverEffect], RoundedRectangle(cornerRadius: 3))
                            .contextMenu {
                                Button("Show transactions", systemImage: "list.bullet") {
                                    onCategoryDataTap(singleData)
                                }
                            }
                            .id(singleData.category.id)
                        }
                    } else {
                        HStack {
                            BasicChartSymbolShape.circle
                                .foregroundStyle(Color.gray.opacity(0.5))
                                .frame(width: 8, height: 8)
                            
                            Text("Epty")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: FTAppAssets.getScreenSize().width / 4 * 1.3)
            .onChange(of: selectedCategoryId) {
                if let selectedCategoryId {
                    withAnimation {
                        proxy.scrollTo(selectedCategoryId)
                    }
                }
            }
        }
    }
    
    private var chartOverlay: some View {
        VStack(spacing: 0) {
            let sumValueDisplay = selectedCategoryId == nil ? sumOfValue : selectedCategoryValue ?? 0
            
            Text(FTFormatters.numberFormatterWithDecimals.string(for: sumValueDisplay) ?? "Err")
                .foregroundStyle(.secondary)
                .bold()
            
            if selectedCategoryId != nil {
                Divider()
                    .padding(.horizontal)
                
                Text("\(selectedCategoryPersentage ?? 0)%")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 110)
    }
    
    //MARK: - Methods
    @ViewBuilder
    private func getAnnotationPopover(value: Float) -> some View {
        let percentage = calculatePercentage(for: value)
        
        Text("\(percentage)%")
            .transaction { $0.animation = nil }
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func calculateTotalValue() -> Float {
        let value = transactionsChartData
            .map { $0.sumValue }
            .reduce(0, +)
        
        return value
    }
    
    private func calculatePercentage(for value: Float) -> Int {
        return Int(value/sumOfValue * 100)
    }
    
    private func setSelectedCategory(_ category: Category?) {
        let categoryId = category?.id
        withAnimation(.snappy(duration: 0.35)) {
            selectedCategoryId = categoryId
        } completion: {
            cancelSelectionAfterDeadline()
        }
    }
    
    private func setSelectedCategoryId() {
        guard let selectedValue else { return }
        var total: Float = 0
        
        for element in transactionsChartData {
            total += element.sumValue
            if Float(selectedValue) <= total {
                setSelectedCategory(element.category)
                return
            }
        }
    }
    
    private func cancelSelectionAfterDeadline() {
        guard selectedCategoryId != nil else { return }
        cancleDispatchWorkItem?.cancel()
        cancleDispatchWorkItem = DispatchWorkItem {
            withAnimation {
                selectedCategoryId = nil
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: cancleDispatchWorkItem!)
    }
    
    private func isSelected(_ category: Category) -> Bool {
        return category.id == selectedCategoryId
    }
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    @StateObject var viewModel = StatisticsViewModel(dataManager: dataManger)
    
    return TransactionPieChart(transactionGroups: viewModel.pieChartTransactionData) { _ in
        
    }
}
