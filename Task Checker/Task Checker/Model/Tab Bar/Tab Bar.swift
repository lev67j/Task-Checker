//
//  Tab Bar.swift
//  Task Checker
//
//  Created by Lev Vlasov on 2025-04-30.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(icon: "house.fill", tag: 0, selectedTab: $selectedTab)
            TabBarButton(icon: "creditcard.fill", tag: 1, selectedTab: $selectedTab)
            TabBarButton(icon: "chart.bar.fill", tag: 2, selectedTab: $selectedTab)
            TabBarButton(icon: "gearshape.fill", tag: 3, selectedTab: $selectedTab)
        }
        .padding(.vertical, 8) // Уменьшенная высота
        .padding(.horizontal, 20) // Средний отступ по краям
        .background(
            Capsule()
                .fill(Color.black)
        )
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
    }
}

struct TabBarButton: View {
    let icon: String
    let tag: Int
    @Binding var selectedTab: Int
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) { // Плавная анимация
                selectedTab = tag
            }
        }) {
            ZStack {
                if selectedTab == tag {
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                }
                
                Image(systemName: icon)
                    .foregroundColor(selectedTab == tag ? .white : .gray)
                    .frame(width: 40, height: 40)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
