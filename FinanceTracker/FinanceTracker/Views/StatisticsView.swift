//
//  StatisticsView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 13.06.2024.
//

import SwiftUI

struct StatisticsView: View {
    //MARK: - Properties
    @StateObject private var viewModel: StatisticsViewModel
    
    //MARK: - Init
    init(viewModel: StatisticsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    totalValueSection
                        .padding(.bottom)

                    TransactionPieChart(transactionGroups: viewModel.pieChartTransactionData)
                        .frame(height: 200)
                }
                .padding()
            }
            .refreshable {
                viewModel.refreshData()
            }
            .navigationTitle("Statistics")
        }
    }
    
    //MARK: - Computed View Props
    private var totalValueSection: some View {
        VStack {
            HStack {
                Text("Total balance")
                    .font(.title2)
                    .bold()
                    .layoutPriority(1)
                
                Spacer()
                
                Menu(viewModel.balanceAccountToFilter.name) {
                    Picker("Picker title", selection: $viewModel.balanceAccountToFilter) {
                        ForEach(viewModel.balanceAccounts) { balanceAccount in
                            Text(balanceAccount.name)
                                .tag(balanceAccount)
                        }
                    }
                }
                .lineLimit(1)
                .buttonStyle(.bordered)
            }
            
            HStack(alignment: .bottom) {
                Text(FTFormatters.numberFormatterWithDecimals.string(for: viewModel.totalForBalanceAccount) ?? "Unable to get")
                    .font(.title)
                    .underline(color: .secondary)
                
                Text(viewModel.balanceAccountToFilter.currency)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.secondarySystemBackground))
        }
    }
    
    //MARK: - Methods
    
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = StatisticsViewModel(dataManager: dataManger)
    
    return StatisticsView(viewModel: viewModel)
}
