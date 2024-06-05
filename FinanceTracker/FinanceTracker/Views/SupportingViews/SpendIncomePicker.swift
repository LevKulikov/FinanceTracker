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
            Text(TransactionsType.spending.rawValue)
                .background {
                    if transactionsTypeSelected == .spending {
                        Capsule()
                            .fill(LinearGradient(colors: [.red, .red.opacity(0.35)], startPoint: .leading, endPoint: .trailing))
                            .padding(-10)
                            .matchedGeometryEffect(id: "transactionsTypeSelect", in: namespace)
                    }
                }
                .onTapGesture {
                    setTransactionType(.spending)
                }
            
            Spacer()
            
            Text(TransactionsType.income.rawValue)
                .background {
                    if transactionsTypeSelected == .income {
                        Capsule()
                            .fill(LinearGradient(colors: [.green.opacity(0.35), .green], startPoint: .leading, endPoint: .trailing))
                            .padding(-10)
                            .matchedGeometryEffect(id: "transactionsTypeSelect", in: namespace)
                    }
                }
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
    @State var type = TransactionsType.spending
    
    return SpendIncomePicker(transactionsTypeSelected: $type)
}
