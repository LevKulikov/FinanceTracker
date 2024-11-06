//
//  TransferTransactionManipulationDelegate.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 29.10.2024.
//


protocol TransferTransactionManipulationDelegate: AnyObject {
    func didAddTransferTransaction(_ transferTransaction: TransferTransaction, from tabView: TabViewType)
    func didUpdateTransferTransaction(_ transferTransaction: TransferTransaction, from tabView: TabViewType)
    func didDeleteTransferTransaction(_ transferTransaction: TransferTransaction, from tabView: TabViewType)
}
