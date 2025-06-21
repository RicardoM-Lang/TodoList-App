import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private init() {
        checkAuthorizationStatus()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func scheduleNotification(for todoItem: TodoItem) {
        guard let dueDate = todoItem.dueDate else { return }
        
        // 创建通知内容
        let content = UNMutableNotificationContent()
        content.title = "待办事项提醒"
        content.body = todoItem.title
        content.sound = .default
        
        // 创建通知触发器
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // 创建通知请求
        let request = UNNotificationRequest(
            identifier: todoItem.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        // 添加通知请求
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    func cancelNotification(for todoItem: TodoItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [todoItem.id.uuidString])
    }
    
    func updateNotification(for todoItem: TodoItem) {
        cancelNotification(for: todoItem)
        if !todoItem.isCompleted {
            scheduleNotification(for: todoItem)
        }
    }
} 