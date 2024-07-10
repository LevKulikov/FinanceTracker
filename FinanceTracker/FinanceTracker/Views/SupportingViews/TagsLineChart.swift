//
//  TagsLineChart.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 10.07.2024.
//

import SwiftUI
import Charts

struct TagChartData: Identifiable, Equatable {
    let id = UUID().uuidString
    let tag: Tag
    let total: Float
}

struct TagsLineChart: View {
    //MARK: - Properties
    let tagData: [TagChartData]
    let maxValue: Float
    private var rowHeight: CGFloat = 27
    
    //MARK: - Init
    init(tagData: [TagChartData]) {
        self.tagData = tagData
        self.maxValue = tagData.map { $0.total }.max() ?? 0
    }
    
    //MARK: - Body
    var body: some View {
        ScrollView {
            HStack {
                tagsView
                
                linesView
                
                totalsView
            }
        }
        .scrollIndicators(.hidden)
    }
    
    //MARK: - View computed props
    private var tagsView: some View {
        VStack(alignment: .leading) {
            ForEach(tagData) { singleTagData in
                Text("# \(singleTagData.tag.name)")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .lineLimit(1)
                    .padding(.horizontal)
                    .padding(.vertical, 5)
                    .background {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(singleTagData.tag.color.opacity(0.15))
                    }
                    .frame(height: rowHeight)
            }
        }
        .frame(maxWidth: 130, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
    }
    
    private var linesView: some View {
        VStack {
            ForEach(tagData) { singleTagData in
                Chart {
                    BarMark(x: .value("Tag total", singleTagData.total), y: .value("Tag name", singleTagData.tag.name))
                        .foregroundStyle(singleTagData.tag.color)
                        .cornerRadius(10)
                }
                .chartLegend(.hidden)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 10)
                .chartXScale(domain: 0...maxValue)
                .frame(height: rowHeight)
            }
        }
    }
    
    private var totalsView: some View {
        VStack(alignment: .trailing) {
            ForEach(tagData) { singleTagData in
                Text(FTFormatters.numberFormatterWithDecimals.string(for: singleTagData.total) ?? "Err")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .frame(height: rowHeight)
            }
        }
    }
    
    //MARK: - Mehtods
    @ViewBuilder
    private func tagStatRow(for singleTagData: TagChartData) -> some View {
        HStack {
            Text("# \(singleTagData.tag.name)")
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .padding(.horizontal)
                .padding(.vertical, 5)
                .background {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(singleTagData.tag.color.opacity(0.15))
                }
                .frame(width: 130, alignment: .leading)
            
            Chart {
                BarMark(x: .value("Tag total", singleTagData.total), y: .value("Tag name", singleTagData.tag.name))
                    .foregroundStyle(singleTagData.tag.color)
                    .cornerRadius(10)
            }
            .chartLegend(.hidden)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 10)
            .chartXScale(domain: 0...maxValue)
            
            Text(FTFormatters.numberFormatterWithDecimals.string(for: singleTagData.total) ?? "Err")
                .foregroundStyle(.secondary)
        }
    }
    
//    private func setMaxValue() async {
//        let max = tagData.map { $0.total }.max() ?? 0
//        maxValue = max
//    }
}

#Preview {
    TagsLineChart(tagData: [])
}
