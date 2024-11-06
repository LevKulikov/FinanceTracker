//
//  TransactionManipulationDelegate.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 29.10.2024.
//


protocol TransactionManipulationDelegate: AnyObject {
    func didUpdateTransaction(_ transaction: Transaction, from tabView: TabViewType)
    func didAddTransaction(_ transaction: Transaction, from tabView: TabViewType)
    func didDeleteTransaction(_ transaction: Transaction?, from tabView: TabViewType)
}