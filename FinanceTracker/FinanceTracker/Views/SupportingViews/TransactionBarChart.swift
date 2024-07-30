//
//  TransactionBarChart.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 15.06.2024.
//

import SwiftUI
import Charts

struct TransactionBarChartData: Identifiable, Hashable {
    enum TransactionBarChartDataType: LocalizedStringResource {
        case spending = "Spending"
        case income = "Income"
        case profit = "Profit"
        case unknown = "Unknown"
        
        var color: Color {
            switch self {
            case .spending:
                return .red
            case .income:
                return .green
            case .profit:
                return .blue
            case .unknown:
                return .yellow
            }
        }
    }
    
    let id: String = UUID().uuidString
    let type: TransactionBarChartDataType
    let value: Float
    let date: Date
}

@MainActor
struct TransactionBarChart: View {
    //MARK: Properties
    private let transactionsData: [[TransactionBarChartData]]
    @Binding private var perDate: BarChartPerDateFilter
    @Binding private var transactionType: TransactionFilterTypes
    
    private var maxVisibleBars: Int {
        let isBothTypesShown = transactionType == .both
        if FTAppAssets.currentUserDevise == .phone {
            return isBothTypesShown ? 5 : 10
        }
        let windowWidth = FTAppAssets.getWindowSize().width
        
        switch windowWidth {
        case ...430:
            return isBothTypesShown ? 5 : 10
        default:
            let ratio = 430 / (isBothTypesShown ? 5 : 10)
            return Int(windowWidth) / ratio
        }
    }
    private var maxXVisibleLenth: Int {
        let multiplier = maxVisibleBars
        let seconds: Int
        switch perDate {
        case .perDay:
            // 86400 seconds in 24 hours
            seconds = 86400
        case .perWeek:
            seconds = 86400 * 7
        case .perMonth:
            seconds = 86400 * 30
        case .perYear:
            seconds = 86400 * 365
        }
        return seconds * multiplier
    }
    private var unit: Calendar.Component {
        switch perDate {
        case .perDay:
            return .day
        case .perWeek:
            return .weekOfYear
        case .perMonth:
            return .month
        case .perYear:
            return .year
        }
    }
    private var componentsToCompare: Set<Calendar.Component> {
        let components: Set<Calendar.Component>
        switch perDate {
        case .perDay:
            components = [.day, .month, .year]
        case .perWeek:
            components = [.weekOfMonth, .month, .year]
        case .perMonth:
            components = [.month, .year]
        case .perYear:
            components = [.year]
        }
        return components
    }
    private var chartXScale: ClosedRange<Date> {
        let calendar = Calendar.current
        switch perDate {
        case .perDay:
            var startDate = calendar.date(byAdding: .month, value: transactionType == .both ? -2 : -3, to: .now) ?? .now
            if let day = calendar.dateComponents([.day], from: .now).day, day < 11 {
                startDate = startDate.startOfMonth() ?? .now
            }
            return startDate...(Date.now.endOfDay() ?? .now)
        case .perWeek:
            let startDate = calendar.date(byAdding: .year, value: transactionType == .both ? -1 : -2, to: .now) ?? .now
            let endDate = Date.now.endOfWeek() ?? .now
            return startDate...endDate
        case .perMonth:
            let startDate = calendar.date(byAdding: .year, value: transactionType == .both ? -3 : -5, to: .now) ?? .now
            let endDate = Date.now.endOfMonth() ?? .now
            return startDate...endDate
        case .perYear:
            let endDate = Date.now.endOfYear() ?? .now
            return FTAppAssets.availableDateRange.lowerBound...endDate
        }
    }
    private var cartMatchingAlignment: DateComponents {
        switch perDate {
        case .perDay:
            return DateComponents(hour: 0)
        case .perWeek:
            return DateComponents(day: 1)
        case .perMonth:
            return DateComponents(day: 1)
        case .perYear:
            return DateComponents(month: 1)
        }
    }
    private var chartMajorAlignment: DateComponents {
        switch perDate {
        case .perDay:
            return DateComponents(day: 1)
        case .perWeek:
            return DateComponents(day: 1)
        case .perMonth:
            return DateComponents(month: 1)
        case .perYear:
            return DateComponents(month: 1)
        }
    }
    private var xScrollPositionEnd: Date {
        return xScrollPosition.addingTimeInterval(Double(maxXVisibleLenth))
    }
    
    @Environment(\.colorScheme) var colorScheme
    @State private var xScrollPosition: Date = (Date.now.endOfDay() ?? .now)
    @State private var yScale: ClosedRange<Float> = 0...50_000
    @State private var selection: Date?
    @State private var selectionBuffer: Date?
    @State private var transactionDataSelected: [TransactionBarChartData]?
    @State private var cancleDispatchWorkItem: DispatchWorkItem?
    @State private var yScaleDispatchWorkItem: DispatchWorkItem?
    
    //MARK: - Init
    init(transactionsData: [[TransactionBarChartData]], perDate: Binding<BarChartPerDateFilter>, transactionType: Binding<TransactionFilterTypes>) {
        self.transactionsData = transactionsData
        self._perDate = perDate
        self._transactionType = transactionType
    }
    
    //MARK: - Body
    var body: some View {
        Chart {
            ForEach(transactionsData, id: \.first?.id) { transactionArray in
                ForEach(transactionArray) { transaction in
                    BarMark(
                        x: .value("Date", transaction.date, unit: unit),
                        y: .value("Transaction", transaction.value)
                    )
                    .foregroundStyle(by: .value("Type", String(localized: transaction.type.rawValue)))
                    .position(by: .value("Type", String(localized: transaction.type.rawValue)), axis: .horizontal)
                    
                    if let selectionBuffer {
                        RuleMark(x: .value("Date", selectionBuffer, unit: unit))
                            .annotation(position: .top, spacing: 0, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                                annotationPopover
                            }
                            .foregroundStyle(by: .value("Type", String(localized: transaction.type.rawValue)))
                    }
                }
            }
        }
        .chartForegroundStyleScale([
            String(localized:TransactionBarChartData.TransactionBarChartDataType.spending.rawValue) : .red,
            String(localized:TransactionBarChartData.TransactionBarChartDataType.income.rawValue) : .green,
            String(localized:TransactionBarChartData.TransactionBarChartDataType.profit.rawValue) : .blue,
            String(localized:TransactionBarChartData.TransactionBarChartDataType.unknown.rawValue) : .yellow,
        ])
        .chartScrollTargetBehavior(
            .valueAligned(
                matching: cartMatchingAlignment,
                majorAlignment: .matching(cartMatchingAlignment)
            )
        )
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: maxXVisibleLenth)
        .chartXScale(domain: chartXScale)
        .chartYScale(domain: yScale)
        .chartScrollPosition(x: $xScrollPosition)
        .chartXSelection(value: $selection)
        .onChange(of: selection, selectTransactionData)
        .onChange(of: xScrollPosition) {
            setSelected(nil, date: nil)
            adaptYAxisScaleToVisibleData()
        }
        .chartXAxis {
            switch perDate {
            case .perDay:
                AxisMarks(values: .stride(by: .day)) { value in
                    if Calendar.current.component(.day, from: value.as(Date.self) ?? .now) == 1 {
                        AxisGridLine().foregroundStyle(colorScheme == .light ? .black : .white)
                        AxisTick().foregroundStyle(colorScheme == .light ? .black : .white)
                        AxisValueLabel(format: .dateTime.month())
                    } else {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.day(.twoDigits))
                    }
                }
            case .perWeek:
                AxisMarks(values: .stride(by: .weekOfYear)) { value in
                    if value.as(Date.self)!.isFirstWeekOfMonth() {
                        AxisGridLine().foregroundStyle(colorScheme == .light ? .black : .white)
                        AxisTick().foregroundStyle(colorScheme == .light ? .black : .white)
                        AxisValueLabel(format: .dateTime.month())
                    } else {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.week(.weekOfMonth))
                    }
                }
            case .perMonth:
                AxisMarks(values: .stride(by: .month)) { value in
                    if value.as(Date.self)!.isFirstMonthOfYear() {
                        AxisGridLine().foregroundStyle(colorScheme == .light ? .black : .white)
                        AxisTick().foregroundStyle(colorScheme == .light ? .black : .white)
                        AxisValueLabel(format: .dateTime.year(.twoDigits))
                    } else {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.narrow))
                    }
                }
            case .perYear:
                AxisMarks(values: .stride(by: .year)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.year(.twoDigits))
                }
            }
        }
        .chartOverlay { _ in
            if transactionsData.isEmpty {
                Label("Empty", systemImage: "xmark.app")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .onChange(of: transactionsData, {
            setSelected(nil, date: nil)
            adaptYAxisScaleToVisibleData(isInitial: true) {
                withAnimation {
                    xScrollPosition = .now
                }
            }
        })
        .onAppear {
            if xScrollPosition.startOfDay() == Date.now.startOfDay() {
                adaptYAxisScaleToVisibleData(isInitial: true) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            xScrollPosition = .now
                        }
                    }
                }
            }
        }
    }
    
    //MARK: Computer properties
    private var annotationPopover: some View {
        VStack(alignment: .leading) {
            if let transactionDataSelected {
                Text(getDateText(transactionDataSelected.first?.date))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                ForEach(transactionDataSelected) { transaction in
                    HStack(alignment: .bottom) {
                        Text(FTFormatters.numberFormatterWithDecimals.string(for: transaction.value) ?? "0")
                            
                        Text(transaction.type.rawValue)
                            .foregroundStyle(transaction.type.color)
                    }
                    .font(.footnote)
                    .fontWeight(.medium)
                }
            }
        }
        .padding(5)
        .background {
            let color = colorScheme == .light ? Color(.secondarySystemBackground) : Color(.systemBackground)
            RoundedRectangle(cornerRadius: 7)
                .stroke(color)
                .fill(color)
        }
    }
    
    //MARK: Methods
    private func getDateText(_ date: Date?) -> String {
        guard let date else { return "" }
        let dateComponents = Calendar.current.dateComponents(componentsToCompare, from: date)
        switch perDate {
        case .perDay:
            return date.formatted(date: .abbreviated, time: .omitted)
        case .perWeek:
            return "Week \(dateComponents.weekOfMonth ?? 0), \(date.month) \(dateComponents.year ?? 0)"
        case .perMonth:
            return "\(date.month) \(dateComponents.year ?? 0)"
        case .perYear:
            return "\(dateComponents.year ?? 0)"
        }
    }
    
    private func selectTransactionData() {
        guard let selection else { return }
        let data = transactionsData.first { isBarDateEqual(left: $0.first?.date, right: selection) }
        if let data {
            setSelected(data, date: selection, withCancelation: true)
        }
    }
    
    private func isBarDateEqual(left: Date?, right: Date?) -> Bool {
        guard let left, let right else { return false }
        let calendar = Calendar.current
        return calendar.dateComponents(componentsToCompare, from: left) == calendar.dateComponents(componentsToCompare, from: right)
    }
    
    private func setSelected(_ data: [TransactionBarChartData]?, date: Date?, withCancelation: Bool = false) {
        selectionBuffer = date
        transactionDataSelected = data
        if withCancelation {
            cancelSelectionAfterDeadline()
        }
    }
    
    private func cancelSelectionAfterDeadline() {
        guard transactionDataSelected != nil else { return }
        cancleDispatchWorkItem?.cancel()
        cancleDispatchWorkItem = DispatchWorkItem {
            withAnimation {
                setSelected(nil, date: nil)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: cancleDispatchWorkItem!)
    }
    
    private func adaptYAxisScaleToVisibleData(isInitial: Bool = false, delayForInitial: Double = 0.5, compeletionHandler: (() -> Void)? = nil) {
        yScaleDispatchWorkItem?.cancel()
        yScaleDispatchWorkItem = DispatchWorkItem {
            setYScaleRange(withAnimation: true)
            compeletionHandler?()
        }
        if isInitial {
            DispatchQueue.main.asyncAfter(deadline: .now() + delayForInitial) {
                let startDate: Date = .now.addingTimeInterval(-Double(maxXVisibleLenth))
                setYScaleRange(withAnimation: true, scrollStart: startDate)
                compeletionHandler?()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: yScaleDispatchWorkItem!)
        }
    }
    
    private func setYScaleRange(withAnimation animated: Bool = false, scrollStart: Date? = nil) {
        let values = transactionsData.flatMap { $0 }.filter {
            ((scrollStart ?? xScrollPosition).addingTimeInterval(-3600)...(scrollStart?.addingTimeInterval(Double(maxXVisibleLenth)) ?? xScrollPositionEnd).addingTimeInterval(-3600)).contains($0.date)
        }.map { $0.value }
        guard var minValue = values.min(), var maxValue = values.max() else { return }
        if minValue > 0 { minValue = 0 }
        
        minValue += (minValue * 0.1)
        maxValue += (maxValue * 0.1)
        
        if animated {
            withAnimation(.easeOut(duration: 0.3)) {
                yScale = minValue...maxValue
            }
        } else {
            yScale = minValue...maxValue
        }
    }
}

#Preview {
    TransactionBarChart(transactionsData: [], perDate: .constant(.perDay), transactionType: .constant(.both))
}
