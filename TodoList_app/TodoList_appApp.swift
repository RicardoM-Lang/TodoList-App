//
//  TodoList_appApp.swift
//  TodoList_app
//
//  Created by 邓智铭 on 2025/3/13.
//

import SwiftUI

@main
struct TodoList_appApp: App {
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationManager)
                .onAppear {
                    notificationManager.requestAuthorization()
                }
        }
    }
}
