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
    @Namespace private var privateNamespace
    @Binding var action: ActionWithTransaction
    @StateObject private var viewModel: AddingSpendIcomeViewModel
    @State private var showMoreCategories = false
    @FocusState private var valueTextFieldFocus
    private var namespaceIdCompetion: String {
        viewModel.transactionToUpdate == nil ? "empty" : viewModel.transactionToUpdate!.id
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
                
                valueTextField
                    .padding(.bottom)
                
                categoryPickerSection
                
//                Image(viewModel.category?.iconName ?? "")
//                    .resizable()
//                    .matchedGeometryEffect(
//                        id: "image" + (viewModel.transactionToUpdate == nil ? "empty" : viewModel.transactionToUpdate!.id),
//                        in: namespace
//                    )
//                    .frame(width: 60, height: 60)
                
                Spacer()
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .background {
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()
                .matchedGeometryEffect(id: "buttonBackground", in: namespace)
        }
        .onTapGesture(perform: dismissKeyboardFocus)
    }
    
    //MARK: Computed View Props
    private var valueTextField: some View {
        HStack {
            TextField("0", text: $viewModel.valueString)
                .focused($valueTextFieldFocus)
                .keyboardType(.decimalPad)
                .autocorrectionDisabled()
                .onChange(of: viewModel.valueString, onChangeOfValueString)
                .font(.title)
            
            Text(viewModel.balanceAccount.currency)
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15.0)
                .fill(.ultraThinMaterial)
                .onTapGesture {
                    valueTextFieldFocus = true
                }
        }
        .padding(.horizontal, 10)
    }
    
    private var categoryPickerSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Category")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("More", systemImage: "chevron.down") {
                    showMoreCategories = true
                }
                .buttonBorderShape(.capsule)
                .buttonStyle(.bordered)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(viewModel.availableCategories) { categoryToSet in
                            getCategoryItem(for: categoryToSet)
                        }
                    }
                }
                .contentMargins(10, for: .scrollContent)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if let cat = viewModel.category {
                            withAnimation {
                                proxy.scrollTo(cat)
                            }
                        }
                    }
                }
                .onReceive(viewModel.$category) { cat in
                    withAnimation {
                        proxy.scrollTo(cat)
                    }
                }
            }
        }
        .sheet(isPresented: $showMoreCategories) {
            wideCategoryPickerView
        }
    }
    
    private var wideCategoryPickerView: some View {
        VStack {
            HStack {
                Text("All Categories")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Close") {
                    showMoreCategories = false
                }
            }
            .padding(.top)
            .padding(.horizontal, 25)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 110))]) {
                    ForEach(viewModel.availableCategories) { categoryToSet in
                        getCategoryItem(for: categoryToSet)
                    }
                }
            }
            .contentMargins(10, for: .scrollContent)
        }
        .presentationBackground(Material.thin)
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(30)
    }
    
    
    //MARK: Methods
    @ViewBuilder
    private func getCategoryItem(for categoryToSet: Category) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        stops: [.init(color: categoryToSet.color.opacity(viewModel.category == categoryToSet ? 0.4 : 0.2), location: 0.7),
                                .init(color: categoryToSet.color, location: 1.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 130)
            
            VStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [categoryToSet.color.opacity(viewModel.category == categoryToSet ? 0.5 : 1), categoryToSet.color.opacity(0.1)],
                                         startPoint: .leading,
                                         endPoint: .trailing)
                    )
                    .overlay {
                        getCategoryImage(for: categoryToSet)
                    }
                    .frame(width: 70)
                
                Spacer()
                
                Text(categoryToSet.name)
                    .bold(viewModel.category == categoryToSet ? true : false)
                    .font(.footnote)
                    .lineLimit(1)
                    .frame(width: 90)
            }
            .padding(.vertical, 12)
        }
        .id(categoryToSet)
        .onTapGesture {
            showMoreCategories = false
            withAnimation {
                viewModel.category = categoryToSet
            }
        }
        .scaleEffect(viewModel.category == categoryToSet ? 1.1 : 1)
        .padding(.horizontal, viewModel.category == categoryToSet ? 6 : 0)
    }
    
    @ViewBuilder
    private func getCategoryImage(for categoryToSet: Category) -> some View {
        let frameDimention: CGFloat = 50
        
        if let uiImage = UIImage(named: categoryToSet.iconName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: frameDimention, height: frameDimention)
        } else {
            Image(systemName: "circle")
                .resizable()
                .scaledToFit()
                .overlay {
                    Image(systemName: "xmark")
                        .font(.title2)
                }
                .frame(width: frameDimention - 10, height: frameDimention - 10)
        }
    }
    
    private func dismissKeyboardFocus() {
        valueTextFieldFocus = false
    }
    
    private func onChangeOfValueString() {
        var copyString = viewModel.valueString
        guard !copyString.isEmpty else { return }
        
        if copyString.contains(",") {
            copyString.replace(",", with: ".")
        }
        
        guard let floatValue = Float(copyString) else {
            viewModel.valueString = ""
            return
        }
        
        viewModel.value = floatValue
        
        if let firstChar = copyString.first, firstChar == "0" {
            viewModel.valueString.removeFirst()
        }
    }
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
