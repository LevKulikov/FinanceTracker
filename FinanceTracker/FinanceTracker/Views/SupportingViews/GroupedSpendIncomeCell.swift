//
//  GroupedSpendIncomeCell.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 03.06.2024.
//

import SwiftUI

struct GroupedSpendIncomeCell: View {
    var transactions: [Transaction]
    var namespace: Namespace.ID
    @Binding var closeGroupFlag: Bool
    let totalValue: Float
    var onTapTransaction: (Transaction) -> Void
    var closeOpenHandler: ((Bool) -> Void)?
    
    @State private var openGroup = false
    private let colorLimit = 5
    private var mutualCategory: Category? {
        return transactions.first?.category
    }
    private var mutualBalanceAccount: BalanceAccount? {
        return transactions.first?.balanceAccount
    }
    private var transactionsValueSum: Float {
        transactions.map { $0.value }.reduce(0, +)
    }
    private var percentageInt: Int {
        let transValue = transactions.map { $0.value }.reduce(0, +)
        guard totalValue > 0, totalValue != .infinity else {
            return transValue > 0 ? 100 : 0
        }
        let percentage = transValue/totalValue
        return Int(percentage * 100)
    }
    private var colorToSet: Color {
        guard let categoryColor = mutualCategory?.color else { return .clear}
        let opacity: Double = Double(percentageInt)/100
        let minLimit: Double = 0.5
        let maxLimit: Double = 0.7
        return categoryColor.opacity(opacity > minLimit ? (opacity < maxLimit ? opacity : maxLimit) : minLimit)
    }
    private var gradientStopLocations: (colorStop: CGFloat, grayStop: CGFloat) {
//        guard transactions.count > 0 else { return (0, 1)}
//        let count = transactions.count
//        guard count < colorLimit else { return (0.6, 1) }
//        let first: CGFloat = 0.05 + CGFloat(count)/10
//        let second: CGFloat = 0.9 - CGFloat(colorLimit - count)/10
//        return (first, second)
        
        let first: CGFloat = 0 + CGFloat(percentageInt)/100
        let second: CGFloat = 1.25 - CGFloat(100 - percentageInt)/100
        return (first, second)
    }
    
    init(transactions: [Transaction], 
         namespace: Namespace.ID,
         closeGroupFlag: Binding<Bool>,
         totalValue: Float,
         onTapTransaction: @escaping (Transaction) -> Void,
         closeOpenHandler: ((Bool) -> Void)? = nil) {
        self.transactions = transactions
        self.namespace = namespace
        self._closeGroupFlag = closeGroupFlag
        self.totalValue = totalValue
        self.onTapTransaction = onTapTransaction
        self.closeOpenHandler = closeOpenHandler
    }
    
    var body: some View {
        VStack {
            if !openGroup {
                groupCellPreview
                    .transition(.blurReplace)
                    .onTapGesture {
                        closeGroupFlag = false
                        withAnimation {
                            openGroup = true
                        }
                    }
            } else {
                groupCellOpenedView
                    .transition(.blurReplace.combined(with: .push(from: .bottom)))
            }
            
            if openGroup {
                ForEach(transactions) { transaction in
                    SpendIncomeCell(transaction: transaction, namespace: namespace)
                        .transition(.blurReplace)
                        .onTapGesture {
                            onTapTransaction(transaction)
                        }
                }
            }
        }
        .padding(.bottom, openGroup ? 20 : 0)
        .onChange(of: closeGroupFlag) {
            if closeGroupFlag {
                withAnimation(.snappy(duration: 0.5)) {
                    openGroup = false
                }
            }
        }
    }
    
    private var groupCellPreview: some View {
        HStack {
            categoryImage
            
            Text(mutualCategory?.name ?? "Error")
                .font(.title3)
                .lineLimit(1)
            
            Spacer()
            
            HStack(alignment: .bottom) {
                Text(FTFormatters.numberFormatterWithDecimals.string(for: transactionsValueSum) ?? "Err")
                    .font(.title3)
                    .bold()
                    .lineLimit(1)
                
                Text(mutualBalanceAccount?.currency ?? "Err")
                    .font(.footnote)
                    .padding(.bottom, 2.6)
                    .lineLimit(1)
                
                Text("\(percentageInt)%")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 2.6)
            }
            .layoutPriority(1)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 25.0)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: colorToSet, location: gradientStopLocations.colorStop),
                            .init(color: Color(.secondarySystemBackground), location: gradientStopLocations.grayStop),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding(.horizontal)
    }
    
    private var groupCellOpenedView: some View {
        HStack {
            Text(mutualCategory?.name ?? "Error")
                .font(.title2)
                .bold()
                .lineLimit(1)
            
            Spacer()
            
            Button("Show less", systemImage: "chevron.up") {
                withAnimation {
                    openGroup = false
                }
            }
            .buttonBorderShape(.capsule)
            .buttonStyle(.bordered)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.horizontal)
        .padding(.top, 20)
    }
    
    @ViewBuilder
    private var categoryImage: some View {
        let frameDimention: CGFloat = 40
        
        if let mutualCategory, let uiImage = FTAppAssets.iconUIImage(name: mutualCategory.iconName) {
            Circle()
                .fill(LinearGradient(colors: [.clear, mutualCategory.color], startPoint: .leading, endPoint: .trailing))
                .overlay {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: frameDimention - 10, height: frameDimention - 10)
                }
                .frame(width: frameDimention, height: frameDimention)
        } else {
            FTAppAssets.emptyIconImage()
                .frame(width: frameDimention, height: frameDimention)
        }
    }
}

#Preview {
    let container = FinanceTrackerApp.createModelContainer()
    let dataManager = DataManager(container: container)
    let viewModel = SpendIncomeViewModel(dataManager: dataManager)
    
    @Namespace var namespace
    @State var flag = false
    
    return GroupedSpendIncomeCell(transactions: viewModel.filteredGroupedTranactions.first ?? [], namespace: namespace, closeGroupFlag: $flag, totalValue: 100) {
        print($0.typeRawValue)
    }
}
