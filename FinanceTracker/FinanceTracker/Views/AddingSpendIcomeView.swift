//
//  AddingSpendIcomeView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 29.05.2024.
//

import SwiftUI

struct AddingSpendIcomeView: View {
    //MARK: Properties
    var namespace: Namespace.ID
    @Namespace private var emptyNamespace
    @Binding var action: ActionWithTransaction
    @StateObject private var viewModel: AddingSpendIcomeViewModel
    private var isAdding: Bool {
        if case .add = action {
            return true
        }
        return false
    }
    
    //MARK: Init
    init(action: Binding<ActionWithTransaction>, namespace: Namespace.ID, viewModel: AddingSpendIcomeViewModel) {
        self._action = action
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.namespace = namespace
        viewModel.action = self.action
    }
    
    //MARK: Body
    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Button("Cancel", systemImage: "xmark") {
                        withAnimation(.snappy(duration: 0.5)) {
                            action = .none
                        }
                    }
                    .buttonBorderShape(.capsule)
                    .buttonStyle(.bordered)
                    .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                SpendIncomePicker(transactionsTypeSelected: $viewModel.transactionsTypeSelected)
                    .matchedGeometryEffect(id: "picker", in: namespace)
                
                Image(viewModel.category?.iconName ?? "")
                    .resizable()
                    .matchedGeometryEffect(
                        id: "image" + (viewModel.transactionToUpdate == nil ? "empty" : viewModel.transactionToUpdate!.id),
                        in: namespace
                    )
                    .frame(width: 60, height: 60)
                
                Spacer()
            }
        }
        .background {
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()
                .matchedGeometryEffect(id: "buttonBackground", in: namespace)
        }
    }
    
    //MARK: Computed View Props
    
    
    //MARK: Methods
    
}

#Preview {
    let container = FinanceTrackerApp.createModelContainer()
    let dataManager = DataManager(container: container)
    let transactionsTypeSelected: TransactionsType = .spending
    let viewModel = AddingSpendIcomeViewModel(dataManager: dataManager, transactionsTypeSelected: transactionsTypeSelected)
    
    @Namespace var namespace
    @State var action: ActionWithTransaction = .add
    
    return AddingSpendIcomeView(action: $action, namespace: namespace, viewModel: viewModel)
}
