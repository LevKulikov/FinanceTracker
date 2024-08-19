//
//  ToastPopsViews.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 19.08.2024.
//

import SwiftUI

struct RootView<Content: View>: View {
    @ViewBuilder var content: Content
    @State private var overlayWindow: UIWindow?
    
    var body: some View {
        content
            .onAppear {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, overlayWindow == nil {
                    let window = PassthroughWindow(windowScene: windowScene)
                    window.backgroundColor = .clear
                    
                    let rootController = UIHostingController(rootView: ToastGroup())
                    rootController.view.frame = windowScene.keyWindow?.frame ?? .zero
                    rootController.view.backgroundColor = .clear
                    
                    window.rootViewController = rootController
                    window.isHidden = false
                    window.isUserInteractionEnabled = true
                    window.tag = 1009
                    
                    overlayWindow = window
                }
            }
    }
}

fileprivate class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let view = super.hitTest(point, with: event) else { return nil }
        
        return rootViewController?.view == view ? nil : view
    }
}

@Observable
final class Toast: Sendable {
    nonisolated static let shared = Toast()
    @MainActor private(set) var toasts: [ToastItem] = []
    
    private init() {}
    
    @MainActor
    func present(
        title: String,
        subtitle: String? = nil,
        symbol: String?,
        tint: Color = .primary,
        isUserInteractionEnabled: Bool = true,
        timing: ToastTime = .medium,
        action: ToastItem.ToastAction? = nil
    ) {
        withAnimation(.snappy) {
            toasts.append(.init(title: title, subtitle: subtitle, symbol: symbol, tint: tint, isUserInteractionEnabled: isUserInteractionEnabled, timing: timing, action: action))
        }
    }
    
    @MainActor
    func removeItem(_ item: ToastItem) {
        toasts.removeAll(where: { $0.id == item.id })
    }
}

struct ToastItem: Identifiable {
    let id: UUID = .init()
    
    let title: String
    let subtitle: String?
    let symbol: String?
    let tint: Color
    let isUserInteractionEnabled: Bool
    let timing: ToastTime
    let action: ToastAction?
    
    struct ToastAction {
        let symbol: String
        let hideAfterAction: Bool
        let action: @Sendable () -> Void
    }
}

enum ToastTime: CGFloat {
    case short = 1.0
    case medium = 2.0
    case long = 3.5
}

fileprivate struct ToastGroup: View {
    private let model = Toast.shared
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets
            
            ZStack {
                ForEach(model.toasts) { toast in
                    ToastView(size: size, item: toast)
                        .scaleEffect(scale(for: toast))
                        .offset(y: offsetY(for: toast))
                        .zIndex(Double(model.toasts.firstIndex(where: { $0.id == toast.id }) ?? 0))
                }
            }
            .padding(.top, safeArea.top == .zero ? 20 : 15)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
    
    @MainActor
    private func offsetY(for item: ToastItem) -> CGFloat {
        let index = CGFloat(model.toasts.firstIndex(where: { $0.id == item.id }) ?? 0)
        let totalCount = CGFloat(model.toasts.count) - 1
        return (totalCount - index) >= 2 ? -20 : ((totalCount - index) * -10)
    }
    
    @MainActor
    private func scale(for item: ToastItem) -> CGFloat {
        let index = CGFloat(model.toasts.firstIndex(where: { $0.id == item.id }) ?? 0)
        let totalCount = CGFloat(model.toasts.count) - 1
        return 1.0 - ((totalCount - index) >= 2 ? 0.2 : ((totalCount - index) * 0.1))
    }
}

fileprivate struct ToastView: View {
    var size: CGSize
    var item: ToastItem
    
    @State private var delayTask: DispatchWorkItem?
    @State private var offsetY: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 0) {
            if let symbol = item.symbol {
                Image(systemName: symbol)
                    .font(.title3)
                    .padding(.trailing, 10)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(item.title)
                    .lineLimit(1)
                
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                        .lineLimit(2)
                }
            }
            
            if let action = item.action {
                Button("", systemImage: action.symbol) {
                    action.action()
                    if action.hideAfterAction {
                        removeToast()
                    }
                }
                .labelStyle(.iconOnly)
                .font(.title3)
                .padding(.leading, 10)
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .foregroundStyle(item.tint == .primary ? .blue : item.tint)
                .scaleEffect(1.25)
            }
        }
        .foregroundStyle(item.tint)
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .background(
            .background
                .shadow(.drop(color: .primary.opacity(0.06), radius: 8, x: 5, y: 5))
                .shadow(.drop(color: .primary.opacity(0.06), radius: 5, x: -5, y: -5)),
            in: .capsule
        )
        .contentShape(.capsule)
        .gesture(
            DragGesture()
                .onChanged { value in
                    cancelDelayTask()
                    let currentY = value.translation.height
                    if currentY < 20 {
                        withAnimation {
                            offsetY = currentY
                        }
                    }
                }
                .onEnded { value in
                    onDragEnded(value)
                }
        )
        .onAppear {
            dispatchDelayTask()
        }
        .frame(maxWidth: size.width * 0.7)
        .offset(y: offsetY)
        .transition(.offset(y: -150))
    }
    
    private func removeToast() {
        if let delayTask {
            delayTask.cancel()
        }
        
        Task { @MainActor [item] in
            withAnimation(.snappy) {
                Toast.shared.removeItem(item)
            }
        }
    }
    
    private func onDragEnded(_ value: DragGesture.Value) {
        guard item.isUserInteractionEnabled else { return }
        let endY = value.translation.height
        if endY < -15 {
            removeToast()
        } else {
            withAnimation {
                offsetY = 0
            }
            dispatchDelayTask()
        }
    }
    
    private func dispatchDelayTask() {
        guard delayTask == nil else { return }
        delayTask = .init(block: {
            removeToast()
        })
        
        if let delayTask {
            DispatchQueue.main.asyncAfter(deadline: .now() + item.timing.rawValue, execute: delayTask)
        }
    }
    
    private func cancelDelayTask() {
        if delayTask != nil {
            delayTask?.cancel()
            delayTask = nil
        }
    }
}
