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
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddingSpendIcomeViewModel
    @State private var showMoreCategories = false
    @State private var showUpdatingCategoryView: Category?
    @State private var showMoreTagsOptions = false
    @State private var showAddingBalanceAccountView = false
    @State private var saveError: AddingSpendIcomeViewModel.SaveErrors?
    @State private var deletionAlert = false
    @State private var didExitByScroll = false
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
    private var isUpdating: Bool {
        if case .update = action {
            return true
        }
        return false
    }
    private var isKeyboardActive: Bool {
        valueTextFieldFocus || searchTagsTextFieldFocus || commentTextFieldFocus
    }
    private var toolbarCanBeDisplayed: Bool {
        !showAddingBalanceAccountView && (showUpdatingCategoryView == nil)
    }
    private var userIdiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    private var frameMaxWidthHeight: (maxWidth: CGFloat, maxHeight: CGFloat) {
        if userIdiom == .phone {
            return (maxWidth: .infinity, maxHeight: .infinity)
        }
        let windowSize = FTAppAssets.getWindowSize()
        let width: CGFloat = FTAppAssets.maxCustomSheetWidth
        let height: CGFloat = windowSize.width > width ? FTAppAssets.maxCustomSheetHeight : .infinity
        return (maxWidth: width, maxHeight: height)
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
        ScrollViewReader { proxy in
            ScrollView {
                VStack {
                    headerSection
                        .padding(.bottom)
                    
                    
                    valueTextField
                        .padding(.bottom)
                    
                    categoryPickerSection
                        .padding(.bottom)
                    
                    Divider()
                        .padding(.horizontal)
                        .padding(.bottom)
                    
                    datePicker
                        .padding(.bottom)
                    
                    Divider()
                        .padding(.horizontal)
                        .padding(.bottom)
                    
                    balanceAccountPicker
                        .padding(.bottom)
                    
                    Divider()
                        .padding(.horizontal)
                        .padding(.bottom)
                    
                    TagsSectionView(viewModel: viewModel, showMoreTagsOptions: $showMoreTagsOptions, focusState: $searchTagsTextFieldFocus)
                        .onChange(of: searchTagsTextFieldFocus) {
                            if searchTagsTextFieldFocus {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    withAnimation {
                                        proxy.scrollTo("existing tags", anchor: .bottom)
                                    }
                                }
                            }
                        }
                    
                    commentSection
                        .padding(.bottom)
                    
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 50)
                }
                .safeAreaInset(edge: .top) {
                    scrollTopToExitGeometry
                }
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: frameMaxWidthHeight.maxWidth, maxHeight: frameMaxWidthHeight.maxHeight)
            .background {
                if userIdiom == .phone {
                    Rectangle()
                        .fill(.background)
                        .ignoresSafeArea()
                } else {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.background)
                        .ignoresSafeArea()
                        .shadow(color: .gray.opacity(0.5), radius: 30)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture {
                        closeView()
                    }
            }
            .toolbar {
                if toolbarCanBeDisplayed {
                    toolbarView
                }
            }
            .onTapGesture(perform: dismissKeyboardFocus)
            .overlay(alignment: .bottom) {
                if !searchTagsTextFieldFocus && !commentTextFieldFocus {
                    addUpdateButton
                        .hoverEffect(.lift)
                }
            }
            .confirmationDialog("Delete transaction?", isPresented: $deletionAlert, titleVisibility: .visible, actions: {
                Button("Delete", role: .destructive) {
                    viewModel.deleteUpdatedTransaction {
                        closeView()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }, message: {
                Text("This action is irretable")
            })
            .alert(
                "\(saveError?.saveErrorLocalizedDescription ?? "Unknown error")",
                isPresented: .init(get: { saveError != nil }, set: { _ in saveError = nil } )
            ) {
                Button("Ok") {}
            }
        }
    }
    
    //MARK: Computed View Props
    private var toolbarView: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            
            Button("", systemImage: "keyboard.chevron.compact.down.fill", action: dismissKeyboardFocus)
                .foregroundStyle(.secondary)
                .labelsHidden()
        }
    }
    
    private var scrollTopToExitGeometry: some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
            EmptyView()
                .onChange(of: minY) {
                    if minY > 150, !didExitByScroll {
                        didExitByScroll = true
                        closeView()
                    }
                }
        }
        .frame(height: 0)
    }
    
    private var headerSection: some View {
        HStack {
            Spacer()
            
            SpendIncomePicker(transactionsTypeSelected: $viewModel.transactionsTypeSelected)
                .matchedGeometryEffect(id: "picker", in: namespace)
                .scaleEffect(0.9)
            
            Spacer()
        }
        .overlay(alignment: .trailing) {
            Button("", systemImage: "xmark") {
                closeView()
            }
            .font(.title)
            .buttonBorderShape(.circle)
            .buttonStyle(.bordered)
            .foregroundStyle(.secondary)
            .hoverEffect(.highlight)
        }
        .overlay(alignment: .leading) {
            if isUpdating {
                Button("", systemImage: "trash") {
                    deletionAlert.toggle()
                }
                .font(.title2)
                .buttonBorderShape(.circle)
                .buttonStyle(.bordered)
                .foregroundStyle(.red)
                .hoverEffect(.highlight)
            }
        }
        .padding(.horizontal, 10)
    }
    
    private var valueTextField: some View {
        HStack {
            TextField("0", text: $viewModel.valueString)
                .focused($valueTextFieldFocus)
                .keyboardType(.decimalPad)
                .autocorrectionDisabled()
                .onChange(of: viewModel.valueString, onChangeOfValueString)
                .font(.title)
                .onSubmit {
                    viewModel.valueString = FTFormatters
                        .numberFormatterWithDecimals
                        .string(for: viewModel.value) ?? ""
                }
                .onAppear {
                    if isAdding {
                        valueTextFieldFocus = true
                    }
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
                .hoverEffect(.highlight)
            }
            .padding(.horizontal, 10)
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(viewModel.availableCategories) { categoryToSet in
                            CategoryItemView(category: categoryToSet, selectedCategory: $viewModel.category)
                                .hoverEffect(.lift)
                                .onTapGesture {
                                    withAnimation {
                                        viewModel.category = categoryToSet
                                    }
                                }
                                .contextMenu {
                                    Button("Update", systemImage: "pencil.and.outline") {
                                        showUpdatingCategoryView = categoryToSet
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
        .sheet(item: $showUpdatingCategoryView) { categoryToUpdate in
            NavigationStack {
                viewModel.getAddingCategoryView(action: .update(categoryToUpdate))
            }
        }
    }
    
    private var wideCategoryPickerView: some View {
        WideCategoryPickerView(
            categories: viewModel.availableCategories,
            selecetedCategory: $viewModel.category,
            show: $showMoreCategories,
            addingNavigationView: viewModel.getAddingCategoryView(action: .add)) { category in
                showMoreCategories = false
                withAnimation {
                    viewModel.category = category
                }
            } contextMenuContent: { category in
                Button("Update", systemImage: "pencil.and.outline") {
                    showMoreCategories = false
                    showUpdatingCategoryView = category
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
                Picker("", selection: $viewModel.date) {
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
                Picker("Balance Accounts", selection: $viewModel.balanceAccount) {
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
                
                Button("Add new", systemImage: "plus") {
                    showAddingBalanceAccountView.toggle()
                }
            }
            .buttonStyle(.bordered)
            .lineLimit(1)
            .foregroundStyle(.primary)
            .hoverEffect(.highlight)
        }
        .padding(.horizontal, 10)
        .sheet(isPresented: $showAddingBalanceAccountView) {
            NavigationStack {
                viewModel.getAddingBalanceAccountView()
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
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
                        .matchedGeometryEffect(id: "buttonBackground", in: namespace)
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
        dismissKeyboardFocus()
        dismiss()
        withAnimation(.snappy(duration: 0.35)) {
            action = .none
        }
    }
}

#Preview {
    let container = FinanceTrackerApp.createModelContainer()
    let dataManager = DataManager(container: container)
    let transactionsTypeSelected: TransactionsType = .spending
    let viewModel = AddingSpendIcomeViewModel(dataManager: dataManager, use: .main, transactionsTypeSelected: transactionsTypeSelected, balanceAccount: .emptyBalanceAccount)
    
    @Namespace var namespace
    @State var action: ActionWithTransaction = .add(.now)
    
    return AddingSpendIcomeView(action: $action, namespace: namespace, viewModel: viewModel)
}
