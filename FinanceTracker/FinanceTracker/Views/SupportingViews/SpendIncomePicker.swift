//
//  SpendIncomePicker.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 26.05.2024.
//

import SwiftUI

struct SpendIncomePicker: View {
    @Binding var transactionsTypeSelected: TransactionsType
    @Namespace private var namespace
    
    var body: some View {
        HStack {
            Text(TransactionsType.spending.localizedString)
                .background {
                    if transactionsTypeSelected == .spending {
                        Capsule()
                            .fill(Color.red.opacity(0.7))
                            .padding(-10)
                            .matchedGeometryEffect(id: "transactionsTypeSelect", in: namespace)
                    }
                }
                .hoverEffect(.lift)
                .onTapGesture {
                    setTransactionType(.spending)
                }
            
            Spacer()
            
            Text(TransactionsType.income.localizedString)
                .background {
                    if transactionsTypeSelected == .income {
                        Capsule()
                            .fill(Color.green.opacity(0.7))
                            .padding(-10)
                            .matchedGeometryEffect(id: "transactionsTypeSelect", in: namespace)
                    }
                }
                .hoverEffect(.lift)
                .onTapGesture {
                    setTransactionType(.income)
                }
        }
        .font(.title2)
        .bold()
        .frame(maxWidth: 250)
        .padding()
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
        }
    }
    
    
    private func setTransactionType(_ type: TransactionsType) {
        withAnimation(.snappy(duration: 0.4)) {
            transactionsTypeSelected = type
        }
    }
}

#Preview {
    @Previewable @State var type = TransactionsType.spending
    
    return SpendIncomePicker(transactionsTypeSelected: $type)
}
