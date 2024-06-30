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
    
    //MARK: - Initializer
    init(viewModel: WelcomeViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                Button("Close", systemImage: "xmark") {
                    closeView()
                }
            }
            
            Spacer()
        }
    }
    
    //MARK: - Computed props
    
    //MARK: - Methods
    private func closeView() {
        dismiss()
    }
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = WelcomeViewModel(dataManager: dataManger)
    
    return WelcomeView(viewModel: viewModel)
}
