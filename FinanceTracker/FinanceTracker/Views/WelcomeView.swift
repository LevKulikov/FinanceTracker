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
    @State private var showCreateBalanceAccount = false
    
    //MARK: - Initializer
    init(viewModel: WelcomeViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        welcomeScroll
    }
    
    //MARK: - Computed props
    private var welcomeScroll: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack {
                    ForEach(0..<viewModel.models.count) { index in
                        SingleExampleView(model: viewModel.models[index])
                            .tag(index)
                            .containerRelativeFrame(.horizontal)
                            .id(index)
                            .scrollTransition(axis: .horizontal) { conent, phase in
                                let maxDegree: Double = 25
                                let rotDegrees: Double = phase == .topLeading ? maxDegree : (phase == .bottomTrailing ? -maxDegree : 0)
                                
                                return conent
                                    .scaleEffect(phase == .identity ? 1 : 0.8)
                                    .blur(radius: phase == .identity ? 0 : 2)
                                    .rotation3DEffect(.degrees(rotDegrees), axis: (x: 0, y: 1, z: 0))
                            }
                            .overlay(alignment: .bottom) {
                                nextCompeteButton(for: index, proxy: proxy)
                                    .padding(.bottom, 25)
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .ignoresSafeArea(edges: .bottom)
            .fullScreenCover(isPresented: $showCreateBalanceAccount, onDismiss: {
                closeView()
            }, content: {
                NavigationStack {
                    viewModel.getAddingBalanceAccauntView()
                }
            })
        }
    }
    
    //MARK: - Methods
    @ViewBuilder
    private func nextCompeteButton(for index: Int, proxy: ScrollViewProxy) -> some View {
        let text: LocalizedStringResource = (index < viewModel.models.count - 1) ? "Next" : "Create"
        
        Button {
            if index < viewModel.models.count - 1 {
                withAnimation {
                    proxy.scrollTo(index + 1)
                }
            } else {
                showCreateBalanceAccount = true
            }
        } label: {
            Text(text)
                .foregroundStyle(.white)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.vertical, 10)
                .padding(.horizontal, 40)
                .background {
                    Capsule()
                        .fill(Color.blue)
                        .shadow(color: .blue, radius: index < viewModel.models.count - 1 ? 0 : 7)
                }
        }
    }
    
    private func closeView() {
        viewModel.welcomeIsPassed()
        dismiss()
    }
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = WelcomeViewModel(dataManager: dataManger)
    
    return WelcomeView(viewModel: viewModel)
}
