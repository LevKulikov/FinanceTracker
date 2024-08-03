//
//  SearchTransactionRow.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 28.06.2024.
//

import SwiftUI

@MainActor
struct SearchTransactionRow: View {
    //MARK: - Properties
    let transaction: Transaction
    private let maxNumberOfTags = 3
    @State private var currency: Currency?
    
    //MARK: - Body
    var body: some View {
        HStack {
            HStack {
                categoryImage
                VStack(alignment: .leading) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(transaction.category?.name ?? "Err")
                                .lineLimit(1)
                            Text(transaction.balanceAccount?.name ?? "Err")
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        HStack(alignment: .bottom, spacing: 3) {
                            Text(FTFormatters.numberFormatterWithDecimals.string(for: transaction.value) ?? "Err")
                                .bold()
                                .foregroundStyle(transaction.type == .spending ? .red : .green)
                            
                            Text(currency?.symbol ?? (transaction.balanceAccount?.currency ?? "Err"))
                                .foregroundStyle(.secondary)
                        }
                        .layoutPriority(1)
                        .lineLimit(1)
                    }
                    
                    if !transaction.tags.isEmpty {
                        HStack {
                            let tags = transaction.tags
                            
                            ForEach(getToSetTags()) { tag in
                                Text("# \(tag.name)")
                                    .foregroundStyle(.secondary)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 5)
                                    .background {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(tag.color.opacity(0.15))
                                    }
                            }
                            
                            if tags.count > maxNumberOfTags {
                                Text("+\(tags.count - maxNumberOfTags)")
                                    .foregroundStyle(.secondary)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .task {
            if let codeString = transaction.balanceAccount?.currency {
                currency = await FTAppAssets.getCurrency(for: codeString)
            }
        }
    }
    
    @ViewBuilder
    private var categoryImage: some View {
        let frameDimention: CGFloat = 40
        
        if let category = transaction.category, let uiImage = FTAppAssets.iconUIImage(name: category.iconName) {
            Circle()
                .fill(LinearGradient(colors: [transaction.category?.color ?? .clear, .clear], startPoint: .leading, endPoint: .trailing))
                .overlay {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: frameDimention - 15, height: frameDimention - 15)
                }
                .frame(width: frameDimention, height: frameDimention)
        } else {
            FTAppAssets.emptyIconImage()
                .frame(width: frameDimention, height: frameDimention)
        }
    }
    
    private func getToSetTags() -> [Tag] {
        var toSetTags = transaction.tags
        if toSetTags.count > maxNumberOfTags {
            toSetTags = Array(toSetTags.prefix(maxNumberOfTags))
        }
        return toSetTags
    }
}

#Preview {
    SearchTransactionRow(transaction: Transaction(type: .spending, comment: "", value: 1000, date: .now, balanceAccount: .emptyBalanceAccount, category: .emptyCategory, tags: []))
}
