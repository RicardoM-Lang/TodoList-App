import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(date: Date(), todos: [
            TodoItem(title: "示例任务 1", priority: .high),
            TodoItem(title: "示例任务 2", priority: .medium),
            TodoItem(title: "示例任务 3", priority: .low)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> ()) {
        let entry = TodoEntry(date: Date(), todos: loadTodos())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = TodoEntry(date: Date(), todos: loadTodos())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    private func loadTodos() -> [TodoItem] {
        guard let data = UserDefaults(suiteName: "group.com.yourdomain.TodoList")?.data(forKey: "todos"),
              let todos = try? JSONDecoder().decode([TodoItem].self, from: data) else {
            return []
        }
        return todos.filter { !$0.isCompleted }
    }
}

struct TodoEntry: TimelineEntry {
    let date: Date
    let todos: [TodoItem]
}

struct TodoListWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(todos: entry.todos)
        case .systemMedium:
            MediumWidgetView(todos: entry.todos)
        case .systemLarge:
            LargeWidgetView(todos: entry.todos)
        default:
            Text("不支持的小组件尺寸")
        }
    }
}

struct SmallWidgetView: View {
    let todos: [TodoItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("待办事项")
                .font(.headline)
            
            if todos.isEmpty {
                Text("没有待办事项")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("\(todos.count) 个待办")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let firstTodo = todos.first {
                    HStack {
                        Circle()
                            .fill(priorityColor(for: firstTodo.priority))
                            .frame(width: 8, height: 8)
                        Text(firstTodo.title)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding()
    }
    
    private func priorityColor(for priority: Priority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

struct MediumWidgetView: View {
    let todos: [TodoItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("待办事项")
                .font(.headline)
            
            if todos.isEmpty {
                Text("没有待办事项")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("\(todos.count) 个待办")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(todos.prefix(3)) { todo in
                    HStack {
                        Circle()
                            .fill(priorityColor(for: todo.priority))
                            .frame(width: 8, height: 8)
                        Text(todo.title)
                            .font(.caption)
                            .lineLimit(1)
                        
                        if let dueDate = todo.dueDate {
                            Spacer()
                            Text(dueDate, style: .time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if todos.count > 3 {
                    Text("还有 \(todos.count - 3) 个待办...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
    
    private func priorityColor(for priority: Priority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

struct LargeWidgetView: View {
    let todos: [TodoItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("待办事项")
                .font(.headline)
            
            if todos.isEmpty {
                Text("没有待办事项")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("\(todos.count) 个待办")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(todos.prefix(5)) { todo in
                    HStack {
                        Circle()
                            .fill(priorityColor(for: todo.priority))
                            .frame(width: 8, height: 8)
                        Text(todo.title)
                            .font(.caption)
                            .lineLimit(1)
                        
                        if let dueDate = todo.dueDate {
                            Spacer()
                            Text(dueDate, style: .time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if todos.count > 5 {
                    Text("还有 \(todos.count - 5) 个待办...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
    
    private func priorityColor(for priority: Priority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

@main
struct TodoListWidget: Widget {
    let kind: String = "TodoListWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodoListWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("待办事项")
        .description("显示您的待办事项列表")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
} 