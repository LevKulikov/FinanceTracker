//
//  SingleExampleView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 01.07.2024.
//

import SwiftUI

@MainActor
struct SingleExampleView: View {
    let model: ExampleModel
    private let currentDevice = FTAppAssets.currentUserDevise
    
    var body: some View {
        ScrollView {
            VStack {
                Image(model.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: currentDevice == .phone ? 550 : 650)
                
                VStack(alignment: .leading) {
                    Text(model.title)
                        .font(.title)
                        .bold()
                        
                    Text(model.text)
                        .padding(.bottom, 30)
                }
                .frame(maxWidth: 900)
            }
            .padding()
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    let model: ExampleModel = .init(
        title: "Simple",
        text: "Easily add your expenses and income",
        imageName: "list page example"
    )
    
    return SingleExampleView(model: model)
}
