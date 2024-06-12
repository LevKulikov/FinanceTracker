//
//  SpendIncomeView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 25.05.2024.
//

import SwiftUI

struct SpendIncomeView: View {
    //MARK: Properties
    private var namespace: Namespace.ID
    @StateObject private var viewModel: SpendIncomeViewModel
    @State private var transactionIdSelected: String = ""
    @State private var closeAllOpenedGroup = false
    @State private var isSomeGroupOpened = false
    //For drag gesture
    @State private var dragXOffset: CGFloat = 0
    
    //MARK: Init
    init(viewModel: SpendIncomeViewModel, namespace: Namespace.ID) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.namespace = namespace
    }
    
    //MARK: Computed View props
    var body: some View {
        ZStack {
            ScrollView {
                VStack {
                    sumAndDateView
                        .offset(x: dragXOffset)
                        .scrollTransition { content, phase in
                            content
                                .offset(y: phase.isIdentity ? 0 : phase == .topLeading ? 100 : -100)
                                .scaleEffect(phase.isIdentity ? 1 : 0.7)
                                .opacity(phase.isIdentity ? 1 : 0)
                        }
                    
                    ForEach(viewModel.filteredGroupedTranactions, id: \.self) { transactionArray in
                        GroupedSpendIncomeCell(
                            transactions: transactionArray,
                            namespace: namespace,
                            closeGroupFlag: $closeAllOpenedGroup
                        ) { transaction in
                            guard viewModel.tapEnabled else { return }
                            viewModel.tapEnabled = false
                            transactionIdSelected = transaction.id
                            withAnimation(.snappy(duration: 0.5)) {
                                viewModel.actionSelected = .update(transaction)
                            }
                        } closeOpenHandler: { isOpen in
                            withAnimation {
                                isSomeGroupOpened = isOpen
                            }
                        }
                    }
                    
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 80)
                }
                .safeAreaInset(edge: .top) {
                    spendIncomePicker
                }
            }
            .scrollIndicators(.hidden)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let xTrans = value.translation.width
                        dragXOffset = xTrans
                    }
                    .onEnded { value in
                        onDragEnded(value: value)
                    }
            )
            
            if case .add = viewModel.actionSelected {
                viewModel.getAddUpdateView(forAction: $viewModel.actionSelected, namespace: namespace)
            } else if case .update = viewModel.actionSelected {
                viewModel.getAddUpdateView(forAction: $viewModel.actionSelected, namespace: namespace)
            }
        }
    }
    
    private var spendIncomePicker: some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
            let scrollViewHeight = proxy.bounds(of: .scrollView(axis: .vertical))?.height ?? 0
            let scaleProgress = minY > 0 ? 1 + max(min(minY / scrollViewHeight, 1), 0) * 0.5 : 1
            let reversedScaleProgress = minY < 0 ? max(((scrollViewHeight + minY) / scrollViewHeight), 0.8) : 1
            let yOffset = minY < 0 ? -minY + max((minY / 5), -5) : 0
            
            HStack {
                Button("", systemImage: "chevron.left") {
                    viewModel.setDate(destination: .back)
                }
                .labelStyle(.iconOnly)
                .font(.title)
                .disabled(!viewModel.movingBackwardDateAvailable)
                .padding(.leading)
                .scaleEffect(reversedScaleProgress, anchor: .topLeading)
                .offset(y: yOffset)
                
                Spacer()
                
                SpendIncomePicker(transactionsTypeSelected: $viewModel.transactionsTypeSelected)
                    .matchedGeometryEffect(id: "picker", in: namespace)
                    .scaleEffect(scaleProgress, anchor: .top)
                    .scaleEffect(reversedScaleProgress, anchor: .top)
                    .offset(y: yOffset)
                
                Spacer()
                
                Button("", systemImage: "chevron.right") {
                    viewModel.setDate(destination: .forward)
                }
                .labelStyle(.iconOnly)
                .font(.title)
                .disabled(!viewModel.movingForwardDateAvailable)
                .padding(.trailing)
                .scaleEffect(reversedScaleProgress, anchor: .topTrailing)
                .offset(y: yOffset)
            }
        }
        .frame(height: 70)
    }
    
    private var sumAndDateView: some View {
        VStack(spacing: 0) {
            HStack {
                Menu {
                    Picker("", selection: $viewModel.balanceAccountToFilter) {
                        ForEach(viewModel.availableBalanceAccounts) { balanceAcc in
                            HStack {
                                Text(balanceAcc.name)
                                
                                if let uiImage = FTAppAssets.iconUIImage(name: balanceAcc.iconName) {
                                    Image(uiImage: uiImage)
                                } else {
                                    Image(systemName: "xmark")
                                }
                            }
                            .tag(balanceAcc)
                        }
                    }
                } label: {
                    Label(viewModel.balanceAccountToFilter.name, systemImage: "chevron.down")
                        .font(.title)
                }
                .foregroundStyle(.primary)

                
                
                Spacer()
            }
            .padding(.bottom)
            
            HStack {
                Text(FTFormatters.numberFormatterWithDecimals.string(for: viewModel.transactionsValueSum) ?? "NaN")
                    .font(.title)
                    .bold()
                    .layoutPriority(1)
                
                Spacer()
                
                DatePicker("", selection: $viewModel.dateSelected.animation(.snappy(duration: 0.5)), in: viewModel.availableDateRange, displayedComponents: .date)
                    .frame(maxWidth: 125)
                    .contentShape([.hoverEffect, .contextMenuPreview], RoundedRectangle(cornerRadius: 8.0))
                    .contextMenu {
                        Button("Current date") {
                            withAnimation {
                                viewModel.dateSelected = .now
                            }
                        }
                    }
            }
            
            if viewModel.filteredGroupedTranactions.isEmpty {
                Text("No \(viewModel.transactionsTypeSelected.rawValue) for this date")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)
            }
        }
        .padding(.horizontal, 20)
        .scrollTransition { content, phase in
            content
                .scaleEffect(phase.isIdentity ? 1 : 0.7, anchor: .leading)
                .opacity(phase.isIdentity ? 1 : 0)
        }
    }
    
    private var addButton: some View {
        Button {
            guard viewModel.tapEnabled else { return }
            viewModel.tapEnabled = false
            withAnimation(.snappy(duration: 0.5)) {
                viewModel.actionSelected = .add(viewModel.dateSelected)
            }
        } label: {
            Label("Add \(viewModel.transactionsTypeSelected == .spending ? "spending" : "income")", systemImage: "plus")
                .frame(width: 200, height: 55)
                .background {
                    Capsule()
                        .fill(.thinMaterial)
//                        .matchedGeometryEffect(id: "buttonBackground", in: namespace)
                }
        }
        .offset(y: -5)
    }
    
    //MARK: Methods
    private func deleteTransaction(_ transaction: Transaction) {
        viewModel.delete(transaction)
    }
    
    private func onDragEnded(value: _ChangedGesture<DragGesture>.Value) {
        let xTrans = value.translation.width
        let screenWidth = FTAppAssets.getScreenSize().width
        // plus is back, minus is forward
        if abs(xTrans) > screenWidth / 4 {
            if xTrans > 0, viewModel.movingBackwardDateAvailable {
                dragXOffset = -screenWidth - 20
            } else if viewModel.movingForwardDateAvailable {
                dragXOffset = screenWidth + 20
            }
            
            viewModel.setDate(destination: xTrans > 0 ? .back : .forward)
        }
            
        withAnimation(.snappy) {
            dragXOffset = 0
        }
    }
}

#Preview {
    let container = FinanceTrackerApp.createModelContainer()
    let dataManager = DataManager(container: container)
    let viewModel = SpendIncomeViewModel(dataManager: dataManager)
    
    @Namespace var namespace
    
    return SpendIncomeView(viewModel: viewModel, namespace: namespace)
}
