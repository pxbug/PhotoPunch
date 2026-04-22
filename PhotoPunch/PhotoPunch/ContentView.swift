//
//  ContentView.swift
//  PhotoPunch
//
//  Created by YunZhi Net Co.,Ltd on 2025/9/10.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house")
                }
                .tag(0)
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
        }
                .tag(1)
        }
    }
}

#Preview {
    ContentView()
}
