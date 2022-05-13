//
//  DataSource.EventKit.Placeholder.swift
//  Calendar
//
//  Created by Денис Либит on 27.04.2022.
//

import SwiftUI
import Calendar


final class PlaceholderVC: UIHostingController<PlaceholderVC.PlaceholderView> {
    required init(
        title: String,
        subtitle: String,
        button: PlaceholderView.ActionButton? = nil
    ) {
        // инициализируемся
        super.init(rootView: PlaceholderView(title: title, subtitle: subtitle, button: button))
    }
    
    required dynamic init?(coder aDecoder: NSCoder) { fatalError() }
}

extension PlaceholderVC {
    struct PlaceholderView: View {
        
        // параметры
        let title: String
        let subtitle: String
        let button: ActionButton?
        
        @State
        private var isExecuting: Bool = false
        
        var body: some View {
            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .center, spacing: 8) {
                        Spacer()
                            .frame(minHeight: 16)
                        
                        // картинка
                        Image(systemName: "lock")
                            .font(.system(size: 96))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        // заголовок
                        Text(self.title)
                            .multilineTextAlignment(.center)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        // подзаголовок
                        Text(self.subtitle)
                            .multilineTextAlignment(.center)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // кнопка
                        if let button = self.button {
                            Button(
                                action: {
                                    Task {
                                        self.isExecuting = true
                                        await button.action()
                                        self.isExecuting = false
                                    }
                                },
                                label: {
                                    Text(button.title)
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .frame(minWidth: 220, minHeight: 32)
                                        .padding(8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(button.color)
                                        )
                                }
                            )
                            .buttonStyle(.plain)
                            .disabled(self.isExecuting)
                            .padding(.top, 16)
                        }
                        
                        Spacer()
                            .frame(minHeight: 16)
                    }
                    .frame(width: geometry.size.width)
                    .frame(minHeight: geometry.size.height - geometry.safeAreaInsets.vertical)
                }
            }
            .animation(.default, value: self.isExecuting)
        }
    }
}

extension PlaceholderVC.PlaceholderView {
    struct ActionButton {
        let title: String
        let color: Color
        
        @MainActor
        let action: () async -> Void
    }
}
