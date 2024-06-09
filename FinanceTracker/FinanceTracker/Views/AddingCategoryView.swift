//
//  AddingCategoryView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 05.06.2024.
//

import SwiftUI

struct AddingCategoryView: View {
    //MARK: Properties
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddingCategoryViewModel
    @FocusState private var nameTextFieldFocus
    @State private var showPreview = false
    @State private var categoryIsAdded = false
    @State private var showMoreIcons = false
    private var isKeyboardActive: Bool {
        nameTextFieldFocus
    }
    private var canBeAdded: Bool {
        guard !viewModel.name.isEmpty else { return false }
        guard !viewModel.iconName.isEmpty else { return false }
        return true
    }
    
    //MARK: Init
    init(viewModel: AddingCategoryViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: Body
    var body: some View {
        ScrollView {
            VStack {
                headerView
                    .padding(.bottom, 10)
                
                if showPreview {
                    categoryPreview
                }
                
                nameSection
                
                Divider()
                    .padding(.horizontal)
                    .padding(.bottom)
                
                typeSelectionSection
                
                Divider()
                    .padding()
                
                iconSelectionSection
                
                Divider()
                    .padding()
                
                colorPickerSection
                    .padding(.bottom)
                
                Rectangle()
                    .fill(.clear)
                    .frame(height: 50)
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .overlay(alignment: .bottom) {
            if !isKeyboardActive {
                addButton
            }
        }
        .overlay {
            if categoryIsAdded {
                addingConfirmedView
            }
        }
        .onTapGesture {
            dismissKeyboard()
        }
        .sheet(isPresented: $showMoreIcons) {
            iconsListView
        }
    }
    
    //MARK: View Propeties
    private var headerView: some View {
        HStack {
            Text("New category")
                .font(.title)
                .bold()
            
            Spacer()
            
            Button(showPreview ? "Hide" : "Preview") {
                withAnimation {
                    showPreview.toggle()
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var categoryPreview: some View {
        CategoryItemView(category: viewModel.categoryPreview, selectedCategory: .constant(nil))
    }
    
    private var nameSection: some View {
        VStack {
            HStack {
                Text("Name")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Spacer()
            }
            .padding(.horizontal)
            
            TextField("Category name", text: $viewModel.name.animation(), prompt: Text("Enter name here"))
                .focused($nameTextFieldFocus)
                .font(.title2)
                .padding(.horizontal)
            
            if nameTextFieldFocus && !viewModel.filteredCategories.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Some existing categories")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(viewModel.filteredCategories) { category in
                                getCategoryPreview(for: category)
                            }
                        }
                    }
                    .contentMargins(12, for: .scrollContent)
                }
                .transition(.blurReplace)
            }
        }
    }
    
    private var typeSelectionSection: some View {
        VStack {
            HStack {
                Text("Of type")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            Picker("Type", selection: $viewModel.transactionType) {
                Text("Spending")
                    .tag(TransactionsType.spending)
                Text("Income")
                    .tag(TransactionsType.income)
            }
            .pickerStyle(.segmented)
            .onTapGesture(count: 20, perform: {
                //Prevents iOS 17 bug
            })
        }
        .padding(.horizontal)
    }
    
    private var iconSelectionSection: some View {
        VStack {
            HStack {
                Text("Icon")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Open", systemImage: "chevron.up") {
                    showMoreIcons.toggle()
                }
                .buttonBorderShape(.capsule)
                .buttonStyle(.bordered)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    let gridSpace: CGFloat = 55
                    LazyHGrid(rows: [GridItem(.fixed(gridSpace)), GridItem(.fixed(gridSpace)), GridItem(.fixed(gridSpace))], spacing: 20) {
                        ForEach(FTAppAssets.defaultIconNames, id: \.self) { iconName in
                            getIconItem(for: iconName)
                                .id(iconName)
                                .scrollTargetLayout()
                                .onTapGesture {
                                    withAnimation {
                                        viewModel.iconName = iconName
                                    }
                                }
                        }
                    }
                }
//                .scrollTargetBehavior(.paging)
                .contentMargins(12, for: .scrollContent)
                .onReceive(viewModel.$iconName) { iconName in
                    withAnimation {
                        proxy.scrollTo(iconName)
                    }
                }
            }
        }
    }
    
    private var iconsListView: some View {
        VStack {
            HStack {
                Text("All Icons")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Close") {
                    showMoreIcons.toggle()
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 25)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 55, maximum: 75))], spacing: 20) {
                    ForEach(FTAppAssets.defaultIconNames, id: \.self) { iconName in
                        getIconItem(for: iconName)
                            .onTapGesture {
                                showMoreIcons.toggle()
                                withAnimation {
                                    viewModel.iconName = iconName
                                }
                            }
                    }
                }
            }
        }
    }
    
    private var colorPickerSection: some View {
        VStack {
            HStack {
                Text("Color")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            HStack {
                ForEach(viewModel.defaultColors, id: \.self) { defaultColor in
                    getColorItem(for: defaultColor)
                    
                    Spacer()
                }
                
                ColorPicker("", selection: $viewModel.categoryColor)
                    .labelsHidden()
                    .overlay {
                        if !viewModel.defaultColors.contains(viewModel.categoryColor) {
                            Image(systemName: "checkmark")
                                .font(.footnote)
                                .foregroundStyle(.white)
                        }
                    }
                    .scaleEffect(!viewModel.defaultColors.contains(viewModel.categoryColor) ? 1.5 : 1.3)
                    .shadow(radius: 5)
                    .onTapGesture(count: 20, perform: {
                        //Prevents iOS 17 bug
                    })
                    .padding(.leading, 6)
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 15)
                    .fill(.gray.opacity(0.15))
            }
        }
        .padding(.horizontal)
    }
    
    private var addButton: some View {
        Button {
            viewModel.saveCategory {
                hideConfirmedView()
                withAnimation {
                    categoryIsAdded = true
                } completion: {
                    dismiss()
                }
            }
        } label: {
            Label("Add", systemImage: "plus")
                .frame(width: 170, height: 50)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .stroke(canBeAdded ? .blue : .gray)
                }
        }
        .disabled(!canBeAdded)
        .offset(y: -5)
    }
    
    private var addingConfirmedView: some View {
        RoundedRectangle(cornerRadius: 20.0)
            .fill(Color.green.opacity(0.4))
            .overlay {
                Image(systemName: "checkmark")
                    .foregroundStyle(.white)
                    .font(.system(size: 50))
                    .bold()
                    .symbolEffect(.bounce, value: categoryIsAdded)
            }
            .frame(width: 100, height: 100)
            .transition(.blurReplace)
    }
    
    //MARK: Methods
    @ViewBuilder
    private func getCategoryPreview(for category: Category) -> some View {
        Text(category.name)
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(category.color.opacity(0.3))
            }
    }
    
    @ViewBuilder
    private func getColorItem(for colorToSet: Color) -> some View {
        Circle()
            .fill(colorToSet)
            .frame(width: 35, height: 35)
            .shadow(radius: 5)
            .onTapGesture {
                withAnimation {
                    viewModel.categoryColor = colorToSet
                }
            }
            .overlay {
                if viewModel.categoryColor == colorToSet {
                    Image(systemName: "checkmark")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
            .scaleEffect(viewModel.categoryColor == colorToSet ? 1.1 : 1)
    }
    
    @ViewBuilder
    private func getIconItem(for iconName: String) -> some View {
        FTAppAssets.iconImageOrEpty(name: iconName)
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40)
            .padding(8)
            .background {
                Circle()
                    .fill(viewModel.iconName == iconName ? viewModel.categoryColor.opacity(0.3) : .gray.opacity(0.3))
            }
    }
    
    private func hideConfirmedView() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                categoryIsAdded = false
            }
        }
    }
    
    private func dismissKeyboard() {
        nameTextFieldFocus = false
    }
}

#Preview {
    let container = FinanceTrackerApp.createModelContainer()
    let dataManager = DataManager(container: container)
    let viewModel = AddingCategoryViewModel(dataManager: dataManager, transactionType: .income)
    
    return AddingCategoryView(viewModel: viewModel)
}