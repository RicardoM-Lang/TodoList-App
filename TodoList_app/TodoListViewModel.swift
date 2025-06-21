import Foundation
import UIKit
import SwiftUI

/// 排序选项
enum SortOption: String, CaseIterable {
    case dateCreated = "创建时间"
    case dueDate = "截止日期"
    case priority = "优先级"
    case title = "标题"
}

/// 待办事项列表的视图模型
class TodoListViewModel: ObservableObject {
    /// 待办事项数组，使用 @Published 实现数据绑定
    @Published var todos: [TodoItem] = []
    /// 背景色
    @Published var backgroundColor: Color {
        didSet {
            saveBackgroundColor()
        }
    }
    /// 卡片背景色
    @Published var cardBackgroundColor: Color {
        didSet {
            saveCardBackgroundColor()
        }
    }
    /// 搜索文本
    @Published var searchText = ""
    /// 当前排序选项
    @Published var sortOption: SortOption = .dateCreated
    /// 排序是否升序
    @Published var sortAscending = true
    /// 选中的标签过滤器
    @Published var selectedTags: Set<String> = []
    
    /// 预设的背景色选项
    static let predefinedColors: [(name: String, color: Color)] = [
        ("天空蓝", Color(red: 0.9, green: 0.95, blue: 1.0)),
        ("薄荷绿", Color(red: 0.9, green: 1.0, blue: 0.95)),
        ("柔粉色", Color(red: 1.0, green: 0.95, blue: 0.95)),
        ("淡紫色", Color(red: 0.95, green: 0.9, blue: 1.0)),
        ("米黄色", Color(red: 1.0, green: 0.98, blue: 0.9)),
        ("珍珠白", Color(red: 0.98, green: 0.98, blue: 0.98)),
    ]
    
    /// 预设的卡片背景色选项
    static let predefinedCardColors: [(name: String, color: Color)] = [
        ("米白", Color(red: 0.98, green: 0.98, blue: 0.96)),
        ("天蓝", Color(red: 0.92, green: 0.96, blue: 1.0)),
        ("薄荷", Color(red: 0.92, green: 1.0, blue: 0.96)),
        ("玫瑰", Color(red: 1.0, green: 0.96, blue: 0.96)),
        ("杏色", Color(red: 1.0, green: 0.98, blue: 0.92)),
        ("薰衣", Color(red: 0.96, green: 0.92, blue: 1.0)),
    ]
    
    /// 获取所有使用过的标签
    var allTags: [String] {
        Array(Set(todos.flatMap { $0.tags })).sorted()
    }
    
    /// 获取统计信息
    var statistics: (total: Int, completed: Int, overdue: Int, upcoming: Int) {
        let now = Date()
        let completed = todos.filter { $0.isCompleted }.count
        let overdue = todos.filter { !$0.isCompleted && ($0.dueDate ?? now) < now }.count
        let upcoming = todos.filter { !$0.isCompleted && ($0.dueDate ?? now) > now }.count
        return (todos.count, completed, overdue, upcoming)
    }
    
    /// 获取已过滤和排序的待办事项
    func filteredAndSortedTodos(showCompleted: Bool) -> [TodoItem] {
        var filtered = todos
        
        // 应用搜索过滤
        if !searchText.isEmpty {
            filtered = filtered.filter { todo in
                todo.title.localizedCaseInsensitiveContains(searchText) ||
                (todo.notes ?? "").localizedCaseInsensitiveContains(searchText) ||
                todo.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // 应用标签过滤
        if !selectedTags.isEmpty {
            filtered = filtered.filter { todo in
                !Set(todo.tags).intersection(selectedTags).isEmpty
            }
        }
        
        // 应用完成状态过滤
        if !showCompleted {
            filtered = filtered.filter { !$0.isCompleted }
        }
        
        // 应用排序
        filtered.sort { todo1, todo2 in
            let ascending = sortAscending ? 1 : -1
            switch sortOption {
            case .dateCreated:
                return todo1.createdAt.compare(todo2.createdAt) == (ascending == 1 ? .orderedAscending : .orderedDescending)
            case .dueDate:
                let date1 = todo1.dueDate ?? .distantFuture
                let date2 = todo2.dueDate ?? .distantFuture
                return date1.compare(date2) == (ascending == 1 ? .orderedAscending : .orderedDescending)
            case .priority:
                let p1 = todo1.priority.rawValue
                let p2 = todo2.priority.rawValue
                return ascending == 1 ? p1 < p2 : p1 > p2
            case .title:
                return (todo1.title.localizedCompare(todo2.title) == .orderedAscending) == (ascending == 1)
            }
        }
        
        return filtered
    }
    
    /// 添加新的待办事项
    /// - Parameters:
    ///   - title: 待办事项标题
    ///   - dueDate: 截止日期（可选）
    ///   - notes: 备注信息（可选）
    ///   - image: 图片（可选）
    ///   - tags: 标签（可选）
    ///   - priority: 优先级（可选）
    func addTodo(title: String, dueDate: Date? = nil, notes: String? = nil, image: UIImage? = nil, tags: [String] = [], priority: Priority = .medium) {
        let imageData = image?.jpegData(compressionQuality: 0.7)
        let todo = TodoItem(title: title, dueDate: dueDate, notes: notes, imageData: imageData, tags: tags, priority: priority)
        todos.append(todo)
        saveTodos()
        
        // 如果设置了截止日期，添加通知
        if dueDate != nil {
            NotificationManager.shared.scheduleNotification(for: todo)
        }
    }
    
    /// 更新现有的待办事项
    /// - Parameters:
    ///   - id: 待办事项的唯一标识符
    ///   - title: 新的标题
    ///   - notes: 新的备注信息（可选）
    ///   - dueDate: 新的截止日期（可选）
    ///   - image: 新的图片（可选）
    ///   - tags: 新的标签（可选）
    ///   - priority: 新的优先级（可选）
    func updateTodo(id: UUID, title: String, notes: String? = nil, dueDate: Date? = nil, image: UIImage? = nil, tags: [String]? = nil, priority: Priority? = nil) {
        if let index = todos.firstIndex(where: { $0.id == id }) {
            var updatedTodo = todos[index]
            
            // 更新所有字段
            updatedTodo.title = title
            updatedTodo.notes = notes
            updatedTodo.dueDate = dueDate
            
            // 更新图片数据
            if let image = image {
                updatedTodo.imageData = image.jpegData(compressionQuality: 0.7)
            } else {
                // 如果 image 为 nil，清除原有的图片数据
                updatedTodo.imageData = nil
            }
            
            // 更新标签
            if let tags = tags {
                updatedTodo.tags = tags
            }
            
            // 更新优先级
            if let priority = priority {
                updatedTodo.priority = priority
            }
            
            // 更新数组中的待办事项
            todos[index] = updatedTodo
            
            // 保存到本地存储
            saveTodos()
            
            // 更新通知
            NotificationManager.shared.updateNotification(for: updatedTodo)
            
            // 发送更新通知
            objectWillChange.send()
            
            // 强制刷新 UI
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    /// 切换待办事项的完成状态
    /// - Parameter todo: 要切换状态的待办事项
    func toggleTodoCompletion(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            var updatedTodo = todos[index]
            updatedTodo.isCompleted.toggle()
            todos[index] = updatedTodo
            saveTodos()
            
            // 更新通知
            NotificationManager.shared.updateNotification(for: updatedTodo)
        }
    }
    
    /// 重新加载数据
    func reloadData() {
        loadTodos()
        objectWillChange.send()
    }
    
    /// 删除待办事项
    func deleteTodo(at indexSet: IndexSet) {
        // 在删除前取消通知
        for index in indexSet {
            let todo = todos[index]
            NotificationManager.shared.cancelNotification(for: todo)
        }
        
        todos.remove(atOffsets: indexSet)
        saveTodos()
    }
    
    /// 将待办事项保存到本地存储
    private func saveTodos() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(todos)
            
            // 保存到主应用的 UserDefaults
            UserDefaults.standard.set(data, forKey: "todos")
            UserDefaults.standard.synchronize()
            
            // 保存到共享的 UserDefaults
            if let sharedDefaults = UserDefaults(suiteName: "group.com.yourdomain.TodoList") {
                sharedDefaults.set(data, forKey: "todos")
                sharedDefaults.synchronize()
            }
        } catch {
            print("保存待办事项失败: \(error.localizedDescription)")
        }
    }
    
    /// 保存背景色到本地存储
    private func saveBackgroundColor() {
        if let colorOption = Self.predefinedColors.first(where: { $0.color == backgroundColor }) {
            UserDefaults.standard.set(colorOption.name, forKey: "backgroundColorName")
        }
    }
    
    /// 从本地存储加载背景色
    private static func loadBackgroundColor() -> Color {
        if let colorName = UserDefaults.standard.string(forKey: "backgroundColorName"),
           let colorOption = predefinedColors.first(where: { $0.name == colorName }) {
            return colorOption.color
        }
        return predefinedColors[0].color
    }
    
    /// 保存卡片背景色到本地存储
    private func saveCardBackgroundColor() {
        if let colorOption = Self.predefinedCardColors.first(where: { $0.color == cardBackgroundColor }) {
            UserDefaults.standard.set(colorOption.name, forKey: "cardBackgroundColorName")
        }
    }
    
    /// 从本地存储加载卡片背景色
    private static func loadCardBackgroundColor() -> Color {
        if let colorName = UserDefaults.standard.string(forKey: "cardBackgroundColorName"),
           let colorOption = predefinedCardColors.first(where: { $0.name == colorName }) {
            return colorOption.color
        }
        return predefinedCardColors[0].color
    }
    
    /// 从本地存储加载待办事项
    private func loadTodos() {
        if let data = UserDefaults.standard.data(forKey: "todos") {
            do {
                let decoder = JSONDecoder()
                todos = try decoder.decode([TodoItem].self, from: data)
                objectWillChange.send()
            } catch {
                print("加载待办事项失败: \(error.localizedDescription)")
                todos = []
            }
        }
    }
    
    /// 初始化视图模型并加载数据
    init() {
        self.backgroundColor = Self.loadBackgroundColor()
        self.cardBackgroundColor = Self.loadCardBackgroundColor()
        loadTodos()
    }
} 
