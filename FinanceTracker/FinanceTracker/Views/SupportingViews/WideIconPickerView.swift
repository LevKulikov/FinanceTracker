//
//  WideIconPickerView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 30.06.2024.
//

import SwiftUI

@MainActor
struct WideIconPickerView: View {
    @Binding var showPicker: Bool
    @Binding var selectIcon: String
    let onSelectColorTint: Color
    
    var body: some View {
        VStack {
            HStack {
                Text("All Icons")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Close") {
                    showPicker.toggle()
                }
                .hoverEffect(.highlight)
            }
            .padding(.top, 20)
            .padding(.horizontal, 25)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 55, maximum: 75))], spacing: 20) {
                    ForEach(FTAppAssets.defaultIconNames, id: \.self) { iconName in
                        getIconItem(for: iconName)
                            .contentShape([.hoverEffect, .contextMenuPreview], Circle())
                            .hoverEffect(.highlight)
                            .onTapGesture {
                                showPicker.toggle()
                                withAnimation {
                                    selectIcon = iconName
                                }
                            }
                    }
                }
                
                VStack {
                    Text("Icons made by Freepik from")
                    Text("www.flaticon.com")
                }
                .padding()
                .padding(.top)
                .foregroundStyle(.secondary)
            }
        }
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
                    .fill(selectIcon == iconName ? onSelectColorTint.opacity(0.3) : .gray.opacity(0.3))
            }
    }
}

#Preview {
    @Previewable @State var show = true
    @Previewable @State var onSelect = ""
    
    return WideIconPickerView(showPicker: $show, selectIcon: $onSelect, onSelectColorTint: .red)
}
