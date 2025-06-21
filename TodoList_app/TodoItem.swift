import Foundation
import UIKit
import SwiftUI

/// 优先级枚举
enum Priority: String, Codable, CaseIterable {
    case low = "低优先级"
    case medium = "中优先级"
    case high = "高优先级"
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high: return "exclamationmark.circle"
        }
    }
}

/// 待办事项数据模型
struct TodoItem: Identifiable, Codable {
    /// 唯一标识符
    var id = UUID()
    /// 待办事项标题
    var title: String
    /// 是否已完成
    var isCompleted: Bool
    /// 截止日期（可选）
    var dueDate: Date?
    /// 备注信息（可选）
    var notes: String?
    /// 图片数据（可选）
    var imageData: Data?
    /// 标签数组
    var tags: [String]
    /// 优先级
    var priority: Priority
    /// 创建时间
    var createdAt: Date
    
    /// 初始化一个新的待办事项
    /// - Parameters:
    ///   - title: 待办事项标题
    ///   - isCompleted: 是否已完成，默认为 false
    ///   - dueDate: 截止日期，可选
    ///   - notes: 备注信息，可选
    ///   - imageData: 图片数据，可选
    ///   - tags: 标签数组，默认为空
    ///   - priority: 优先级，默认为中等
    init(title: String,
         isCompleted: Bool = false,
         dueDate: Date? = nil,
         notes: String? = nil,
         imageData: Data? = nil,
         tags: [String] = [],
         priority: Priority = .medium) {
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.notes = notes
        self.imageData = imageData
        self.tags = tags
        self.priority = priority
        self.createdAt = Date()
    }
} 