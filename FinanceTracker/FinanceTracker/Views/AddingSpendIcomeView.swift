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
    @State private var showMoreTagsOptions = false
    @State private var showSaveAlert = false
    @State private var saveError: AddingSpendIcomeViewModel.SaveErrors?
    @FocusState private var valueTextFieldFocus
    @FocusState private var searchTagsTextFieldFocus
    @FocusState private var commentTextFieldFocus
    private var namespaceIdCompetion: String {
        viewModel.transactionToUpdate == nil ? "empty" : viewModel.transactionToUpdate!.id
    }
    private var isAdding: Bool {
        if case .add = action {
            return true
        }
        return false
    }
    private var isKeyboardActive: Bool {
        valueTextFieldFocus || searchTagsTextFieldFocus || commentTextFieldFocus
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
                    Spacer()
                    
                    SpendIncomePicker(transactionsTypeSelected: $viewModel.transactionsTypeSelected)
                        .matchedGeometryEffect(id: "picker", in: namespace)
                        .scaleEffect(0.9)
                    
                    Spacer()
                }
                .overlay(alignment: .leading) {
                    Button("", systemImage: "xmark") {
                        closeView()
                    }
                    .font(.title)
                    .buttonBorderShape(.circle)
                    .buttonStyle(.bordered)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.bottom)
                
                
                valueTextField
                    .padding(.bottom)
                
                categoryPickerSection
                    .padding(.bottom)
                
                datePicker
                    .padding(.bottom)
                
                balanceAccountPicker
                    .padding(.bottom)
                
                TagsSectionView(viewModel: viewModel, showMoreTagsOptions: $showMoreTagsOptions, focusState: $searchTagsTextFieldFocus)
                
                commentSection
                    .padding(.bottom)
                
                Rectangle()
                    .fill(.clear)
                    .frame(height: 50)
            }
        }
        .background {
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()
                .matchedGeometryEffect(id: "buttonBackground", in: namespace)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                
                Button("", systemImage: "keyboard.chevron.compact.down.fill", action: dismissKeyboardFocus)
                    .foregroundStyle(.secondary)
                    .labelsHidden()
            }
        }
        .onTapGesture(perform: dismissKeyboardFocus)
        .overlay(alignment: .bottom) {
            if !isKeyboardActive {
                addUpdateButton
            }
        }
        .alert(
            "\(saveError?.localizedDescription ?? "Unknown error")",
            isPresented: .init(get: { saveError != nil }, set: { _ in saveError = nil } )) {
                Button("Ok") {}
            }
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
                .onSubmit {
                    viewModel.valueString = AppFormatters
                        .numberFormatterWithDecimals
                        .string(for: viewModel.value) ?? ""
                }
            
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
                            CategoryItemView(category: categoryToSet, selectedCategory: $viewModel.category)
                                .onTapGesture {
                                    withAnimation {
                                        viewModel.category = categoryToSet
                                    }
                                }
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
        NavigationStack {
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
                .padding(.top, 20)
                .padding(.horizontal, 25)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 110))]) {
                        ForEach(viewModel.availableCategories) { categoryToSet in
                            CategoryItemView(category: categoryToSet, selectedCategory: $viewModel.category)
                                .onTapGesture {
                                    showMoreCategories = false
                                    withAnimation {
                                        viewModel.category = categoryToSet
                                    }
                                }
                        }
                        
                        NavigationLink {
                            
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(.white)
                                .font(.system(size: 50, weight: .medium))
                                .padding(8)
                                .background {
                                    Circle()
                                        .fill(.blue)
                                }
                        }
                    }
                }
                .contentMargins(10, for: .scrollContent)
            }
        }
        .presentationBackground(Material.thin)
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(30)
    }
    
    private var datePicker: some View {
        VStack(alignment: .leading) {
            Text("Date")
                .font(.title2)
                .fontWeight(.medium)
            
            HStack {
                Picker("ffsf", selection: $viewModel.date) {
                    ForEach(viewModel.threeDatesArray, id: \.self) { dateToSet in
                        Text("\(dateToSet.get(.day)) \(dateToSet.month)")
                            .tag(dateToSet)
                    }
                }
                .pickerStyle(.segmented)
                .scaleEffect(y: 1.1)
                
                DatePicker("", selection: $viewModel.date, in: viewModel.availableDateRange, displayedComponents: .date)
                    .labelsHidden()
            }
            .onTapGesture(count: 20) {
                // overrides tap gesture to fix ios 17.1 bug
            }
        }
        .padding(.horizontal, 10)
    }
    
    private var balanceAccountPicker: some View {
        HStack {
            Text("Balance Account")
                .font(.title2)
                .fontWeight(.medium)
                .layoutPriority(1)
            
            Spacer()
            
            Menu(viewModel.balanceAccount.name) {
                Picker("", selection: $viewModel.balanceAccount) {
                    ForEach(viewModel.availableBalanceAccounts) { balanceAcc in
                        Text(balanceAcc.name)
                            .tag(balanceAcc)
                    }
                }
            }
            .buttonStyle(.bordered)
            .lineLimit(1)
            .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
    }
    
    private var commentSection: some View {
        TextField("Comment", text: $viewModel.comment, prompt: Text("Enter comment"), axis: .vertical)
            .lineLimit(3...5)
            .focused($commentTextFieldFocus)
            .padding(10)
            .background(.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal, 10)
    }
    
    private var addUpdateButton: some View {
        Button {
            viewModel.saveTransaction { error in
                guard let error else {
                    closeView()
                    return
                }
                saveError = error
            }
        } label: {
            Label(isAdding ? "Add" : "Update", systemImage: isAdding ? "plus" : "pencil.and.outline")
                .frame(width: 170, height: 50)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .stroke(.blue)
                }
        }
        .offset(y: -5)
    }
    
    //MARK: Methods
    private func dismissKeyboardFocus() {
        valueTextFieldFocus = false
        searchTagsTextFieldFocus = false
        commentTextFieldFocus = false
    }
    
    private func onChangeOfValueString() {
        var copyString = viewModel.valueString
        guard !copyString.isEmpty else { return }
        
        if copyString.contains(",") {
            copyString.replace(",", with: ".")
        }
        
        if copyString.contains(" ") {
            copyString.replace(" ", with: "")
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
    
    private func closeView() {
        withAnimation(.snappy(duration: 0.5)) {
            action = .none
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
