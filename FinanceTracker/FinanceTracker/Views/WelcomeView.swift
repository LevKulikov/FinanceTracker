//
//  WelcomeView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 30.06.2024.
//

import SwiftUI

struct WelcomeView: View {
    //MARK: - Properties
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: WelcomeViewModel
    @State private var selection: Int = 0
    @State private var showCreateBalanceAccount = false
    private var buttonGradientStopLoaction: CGFloat {
        let pageNumber = CGFloat(selection + 1)
        let count = CGFloat(viewModel.models.count)
        return (pageNumber/count)
    }
    private var buttonText: String {
        if selection < viewModel.models.count - 1 {
            return "Next"
        } else {
            return "Create"
        }
    }
    
    //MARK: - Initializer
    init(viewModel: WelcomeViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        TabView(selection: $selection.animation()) {
            ForEach(0..<viewModel.models.count) { index in
                SingleExampleView(model: viewModel.models[index])
                    .tag(index)
                    .padding(.vertical)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .indexViewStyle(.page(backgroundDisplayMode: .never))
        .padding(.bottom, 15)
        .ignoresSafeArea(edges: .bottom)
        .overlay(alignment: .topTrailing) {
            skipButton
                .padding(.trailing)
                .contextMenu {
                    Button("Close") {
                        closeView()
                    }
                }
        }
        .overlay(alignment: .bottom) {
            bottomButton
        }
        .fullScreenCover(isPresented: $showCreateBalanceAccount, onDismiss: {
            closeView()
        }, content: {
            NavigationStack {
                viewModel.getAddingBalanceAccauntView()
            }
        })
    }
    
    //MARK: - Computed props
    private var skipButton: some View {
        Button("Skip", systemImage: "arrowshape.turn.up.forward.fill") {
            withAnimation {
                selection = viewModel.models.count - 1
            }
        }
        .foregroundStyle(.secondary)
    }
    
    private var bottomButton: some View {
        Button {
            bottomButtonAction()
        } label: {
            Text(buttonText)
                .blendMode(.difference)
                .font(.title2)
                .padding(.vertical, 10)
                .padding(.horizontal, 40)
                .background {
                    Capsule()
                        .fill(
                            LinearGradient(
                                stops: [.init(color: .blue.opacity(0.7), location: buttonGradientStopLoaction), .init(color: .clear, location: 01)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .stroke(Color.secondary)
                        .shadow(color: .blue, radius: selection == viewModel.models.count - 1 ? 10 : 0)
                }
        }
        .bold(selection == viewModel.models.count - 1)
    }
    
    //MARK: - Methods
    private func closeView() {
        viewModel.welcomeIsPassed()
        dismiss()
    }
    
    private func bottomButtonAction() {
        if selection < viewModel.models.count - 1 {
            withAnimation {
                selection += 1
            }
        } else {
            showCreateBalanceAccount = true
        }
    }
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = WelcomeViewModel(dataManager: dataManger)
    
    return WelcomeView(viewModel: viewModel)
}
