//
//  TransferTransactionManipulationDelegate.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 29.10.2024.
//


protocol TransferTransactionManipulationDelegate: AnyObject {
    func didAddTransferTransaction(_ transferTransaction: TransferTransaction)
    func didUpdateTransferTransaction(_ transferTransaction: TransferTransaction)
    func didDeleteTransferTransaction(_ transferTransaction: TransferTransaction)
}