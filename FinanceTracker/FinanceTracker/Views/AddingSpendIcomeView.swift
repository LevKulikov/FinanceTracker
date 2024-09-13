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
    @State private var showCalculatorSigns = false
    @State private var calculatedValueString = ""
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
                        .padding(.bottom, 30)
                    
                    VStack {
                        datePicker
                            .padding(.bottom)
                        
                        Divider()
                            .padding(.horizontal)
                            .padding(.bottom)
                        
                        balanceAccountPicker
                    }
                    .padding(10)
                    .background {
                        RoundedRectangle(cornerRadius: 15.0)
                            .fill(.ultraThinMaterial)
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 30)
                    
                    VStack {
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
                    }
                    .padding(.vertical)
                    .background {
                        RoundedRectangle(cornerRadius: 15.0)
                            .fill(.ultraThinMaterial)
                    }
                    .padding(.horizontal, 10)
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
            if valueTextFieldFocus {
                HStack {
                    Button("", systemImage: showCalculatorSigns ? "multiply.circle" : "plus.forwardslash.minus") {
                        showCalculatorSigns.toggle()
                    }
                    .labelStyle(.iconOnly)
                    .padding(.trailing)
                    
                    if showCalculatorSigns {
                        HStack {
                            Button("", systemImage: "plus") {
                                viewModel.valueString.append(" + ")
                            }
                            
                            Spacer()
                            
                            Button("", systemImage: "minus") {
                                viewModel.valueString.append(" - ")
                            }
                            
                            Spacer()
                            
                            Button("", systemImage: "multiply") {
                                viewModel.valueString.append(" × ")
                            }
                            
                            Spacer()
                            
                            Button("", systemImage: "divide") {
                                viewModel.valueString.append(" ÷ ")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .labelStyle(.iconOnly)
                    } else {
                        Spacer()
                    }
                    
                    Button("", systemImage: "keyboard.chevron.compact.down.fill", action: dismissKeyboardFocus)
                        .labelsHidden()
                        .padding(.leading)
                }
            } else {
                Spacer()
                
                Button("", systemImage: "keyboard.chevron.compact.down.fill", action: dismissKeyboardFocus)
                    .labelsHidden()
            }
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
        VStack {
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
            
            if !calculatedValueString.isEmpty {
                Text(calculatedValueString)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.title2)
                    .bold()
            }
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
                        Text("\(dateToSet.get(.day)) \(dateToSet.month.prefix(3)).")
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
        guard !copyString.isEmpty else {
            calculatedValueString = ""
            return
        }
        
        // replace comma with dot
        if copyString.contains(",") {
            copyString.replace(",", with: ".")
        }
        
        // remove spaces
        if copyString.contains(" ") {
            copyString.replace(" ", with: "")
        }
        
        let signsArray: [String] = ["×", "÷", "-", "+"]
        
        // check if value starts with math sing, which is not allowed
        if let first = copyString.first, signsArray.contains(String(first)) {
            viewModel.valueString = ""
            return
        }
        
        // check if value ends with 2 math sings, and replace previous one with the last
        let lastTwo = Array(copyString.suffix(2)).map { String($0) }
        if lastTwo.count > 1 {
            if signsArray.contains(lastTwo[0]) && signsArray.contains(lastTwo[1]) {
                copyString.removeLast(2)
                copyString += lastTwo[1]
                viewModel.valueString.removeLast(6) // space + sing + space 2 times = 6
                viewModel.valueString += " \(lastTwo[1]) "
            }
        }
        
        // final step - get value. If there are math signs, calculation is taken, if there is not, just check that value is number
        if copyString.contains(where: { signsArray.contains(String($0)) }) {
            let strArr = splitStringToFormulaArray(string: copyString)
            guard let floatValue = calculate(formulaArray: strArr) else {
                return
            }
            
            viewModel.value = floatValue
            calculatedValueString = "= \(FTFormatters.numberFormatterWithDecimals.string(for: floatValue) ?? "Err")"
        } else {
            guard let floatValue = Float(copyString) else {
                viewModel.valueString = ""
                return
            }
            
            viewModel.value = floatValue
            calculatedValueString = ""
            
            if let firstChar = copyString.first, firstChar == "0" {
                viewModel.valueString.removeFirst()
            }
        }
    }
    
    private func closeView() {
        dismissKeyboardFocus()
        dismiss()
        withAnimation(.snappy(duration: 0.35)) {
            action = .none
        }
    }
    
    private func splitStringToFormulaArray(string: String) -> [String] {
        guard string.count > 1 else { return [string]}
        var stringArray: [String] = []
        
        func splitAndInsert(by sign: String) {
            if stringArray.isEmpty {
                let multiplierArray = string.split(separator: sign, omittingEmptySubsequences: true).map { String($0) }
                stringArray = multiplierArray
                for i in 1..<multiplierArray.count {
                    stringArray.insert(sign, at: i+i-1)
                }
            } else {
                let multiplierArray = stringArray.flatMap { element in
                    if element.contains(sign) {
                        var arr = element.split(separator: sign, omittingEmptySubsequences: true).map { String($0) }
                        let count = arr.count
                        for i in 1..<count {
                            arr.insert(sign, at: i+i-1)
                        }
                        return arr
                    }
                    return [element]
                }
                stringArray = multiplierArray
            }
        }
        
        if string.contains("÷") {
            let dividerArray = string.split(separator: "÷", omittingEmptySubsequences: true).map { String($0) }
            stringArray = dividerArray
            for i in 1..<dividerArray.count {
                stringArray.insert("÷", at: i+i-1)
            }
        }
        
        if string.contains("×") {
            splitAndInsert(by: "×")
        }
        
        if string.contains("+") {
            splitAndInsert(by: "+")
        }
        
        if string.contains("-") {
            splitAndInsert(by: "-")
        }
        
        return stringArray
    }
    
    func calculate(formulaArray: [String]) -> Float? {
        guard formulaArray.count > 1 else {
            guard let first = formulaArray.first else { return nil }
            return Float(first)
        }
        var copyArray = formulaArray
        
        func calculateBySing(sing: String) {
            func doMath(left: Float, right: Float) -> Float? {
                switch sing {
                case "/", "÷":
                    return left / right
                case "x", "*", "×":
                    return left * right
                case "+":
                    return left + right
                case "-":
                    return left - right
                default:
                    return nil
                }
            }
            
            var copy = copyArray
            while let divideIndex = copy.firstIndex(of: sing) {
                let prevIndex = divideIndex - 1
                let nextIndex = divideIndex + 1
                guard prevIndex >= 0, nextIndex < copy.count else { return }
                // Getting numbers
                let prevStr = copy[prevIndex]
                let nextStr = copy[nextIndex]
                // Making math
                guard let prevNumber = Float(prevStr) else { return }
                guard let nextNumber = Float(nextStr) else { return }
                guard let exitNumber = doMath(left: prevNumber, right: nextNumber) else { return }
                // Removing numbers and sing from array
                copy.remove(at: nextIndex)
                copy.remove(at: divideIndex)
                copy.remove(at: prevIndex)
                // Inserting exit number in array
                let exitStr = String(exitNumber)
                copy.insert(exitStr, at: prevIndex)
            }
            
            copyArray = copy
        }
        
        if copyArray.contains("÷") {
            calculateBySing(sing: "÷")
        }
        
        if copyArray.contains("×") {
            calculateBySing(sing: "×")
        }
        
        if copyArray.contains("-") {
            calculateBySing(sing: "-")
        }
        
        if copyArray.contains("+") {
            calculateBySing(sing: "+")
        }
        
        guard let resultString = copyArray.first else { return nil }
        return Float(resultString)
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
