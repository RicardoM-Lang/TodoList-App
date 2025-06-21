//
//  ContentView.swift
//  TodoList_app
//
//  Created by 邓智铭 on 2025/3/13.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Properties
    /// 视图模型，管理待办事项数据
    @StateObject private var viewModel = TodoListViewModel()
    /// 控制是否显示添加新待办事项的sheet
    @State private var isAddingNew = false
    /// 控制是否显示编辑待办事项的sheet
    @State private var editingTodoId: UUID? = nil
    /// 控制是否显示背景色选择
    @State private var isShowingColorPicker = false
    /// 控制是否显示统计视图
    @State private var isShowingStats = false
    /// 控制是否显示排序选项
    @State private var isShowingSortOptions = false
    /// 新待办事项的标题
    @State private var newTodoTitle = ""
    /// 控制是否显示已完成的任务
    @State private var showCompletedTasks = false
    /// 控制是否显示卡片颜色选择器
    @State private var isShowingCardColorPicker = false
    
    // MARK: - Theme Colors
    private let mainBlue = Color(red: 0.2, green: 0.5, blue: 0.9)
    private let lightBlue = Color(red: 0.9, green: 0.95, blue: 1.0)
    private let darkBlue = Color(red: 0.1, green: 0.3, blue: 0.7)
    
    // MARK: - Keyboard Handling
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Computed Properties
    /// 根据显示选项过滤待办事项
    var filteredTodos: [TodoItem] {
        viewModel.todos.filter { todo in
            showCompletedTasks || !todo.isCompleted
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // 背景色
                viewModel.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 搜索栏
                    SearchBar(text: $viewModel.searchText)
                        .padding()
                    
                    // 标签过滤器
                    if !viewModel.allTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(viewModel.allTags), id: \.self) { tag in
                                    TagView(tag: tag, isSelected: viewModel.selectedTags.contains(tag)) {
                                        withAnimation {
                                            if viewModel.selectedTags.contains(tag) {
                                                viewModel.selectedTags.remove(tag)
                                            } else {
                                                viewModel.selectedTags.insert(tag)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom)
                    }
                    
                    // 待办事项列表
                    List {
                        ForEach(viewModel.filteredAndSortedTodos(showCompleted: showCompletedTasks)) { todo in
                            TodoRowView(todo: todo, onToggle: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.toggleTodoCompletion(todo)
                                }
                            }, onEdit: {
                                editingTodoId = todo.id
                            }, mainBlue: mainBlue, viewModel: viewModel)
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .animation(.easeInOut, value: todo.isCompleted)
                            .transition(.opacity)
                        }
                        .onDelete { indexSet in
                            withAnimation {
                                viewModel.deleteTodo(at: indexSet)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        viewModel.reloadData()
                    }
                    
                    // 底部工具栏
                    VStack(spacing: 0) {
                        Divider()
                        HStack(spacing: 16) {
                            // 显示已完成任务按钮
                            Button(action: {
                                withAnimation {
                                    showCompletedTasks.toggle()
                                }
                            }) {
                                Image(systemName: showCompletedTasks ? "checkmark.circle.fill" : "checkmark.circle")
                                    .foregroundColor(mainBlue)
                                    .frame(width: 24, height: 24)
                            }
                            
                            Spacer()
                            
                            // 背景色按钮
                            Button(action: {
                                isShowingColorPicker = true
                            }) {
                                Image(systemName: "paintpalette")
                                    .foregroundColor(mainBlue)
                                    .frame(width: 24, height: 24)
                            }
                            
                            // 卡片颜色按钮
                            Button(action: {
                                isShowingCardColorPicker = true
                            }) {
                                Image(systemName: "rectangle.fill")
                                    .foregroundColor(mainBlue)
                                    .frame(width: 24, height: 24)
                            }
                            
                            // 排序按钮
                            Button(action: {
                                isShowingSortOptions = true
                            }) {
                                Image(systemName: "arrow.up.arrow.down")
                                    .foregroundColor(mainBlue)
                                    .frame(width: 24, height: 24)
                            }
                            
                            // 统计按钮
                            Button(action: {
                                isShowingStats = true
                            }) {
                                Image(systemName: "chart.bar")
                                    .foregroundColor(mainBlue)
                                    .frame(width: 24, height: 24)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.8))
                    }
                }
            }
            .navigationTitle("待办事项")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isAddingNew = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(mainBlue)
                    }
                }
            }
            .sheet(isPresented: $isAddingNew) {
                NavigationView {
                    AddTodoView(isPresented: $isAddingNew, onAdd: { title, date, notes, image, tags, priority in
                        withAnimation {
                            viewModel.addTodo(title: title, dueDate: date, notes: notes, image: image, tags: tags, priority: priority)
                        }
                    }, mainBlue: mainBlue)
                }
            }
            .sheet(isPresented: $isShowingColorPicker) {
                NavigationView {
                    BackgroundColorPicker(selectedColor: $viewModel.backgroundColor)
                        .navigationTitle("选择背景色")
                        .navigationBarItems(trailing: Button("完成") {
                            isShowingColorPicker = false
                        })
                }
            }
            .sheet(isPresented: $isShowingCardColorPicker) {
                NavigationView {
                    CardColorPicker(selectedColor: $viewModel.cardBackgroundColor)
                        .navigationTitle("选择卡片颜色")
                        .navigationBarItems(trailing: Button("完成") {
                            isShowingCardColorPicker = false
                        })
                }
            }
            .sheet(isPresented: $isShowingStats) {
                NavigationView {
                    StatisticsView(viewModel: viewModel)
                        .navigationBarItems(trailing: Button("完成") {
                            isShowingStats = false
                        })
                }
            }
            .actionSheet(isPresented: $isShowingSortOptions) {
                ActionSheet(title: Text("排序方式"), buttons: [
                    .default(Text("创建时间 \(viewModel.sortOption == .dateCreated ? (viewModel.sortAscending ? "↑" : "↓") : "")")) {
                        if viewModel.sortOption == .dateCreated {
                            viewModel.sortAscending.toggle()
                        } else {
                            viewModel.sortOption = .dateCreated
                            viewModel.sortAscending = true
                        }
                    },
                    .default(Text("截止日期 \(viewModel.sortOption == .dueDate ? (viewModel.sortAscending ? "↑" : "↓") : "")")) {
                        if viewModel.sortOption == .dueDate {
                            viewModel.sortAscending.toggle()
                        } else {
                            viewModel.sortOption = .dueDate
                            viewModel.sortAscending = true
                        }
                    },
                    .default(Text("优先级 \(viewModel.sortOption == .priority ? (viewModel.sortAscending ? "↑" : "↓") : "")")) {
                        if viewModel.sortOption == .priority {
                            viewModel.sortAscending.toggle()
                        } else {
                            viewModel.sortOption = .priority
                            viewModel.sortAscending = true
                        }
                    },
                    .default(Text("标题 \(viewModel.sortOption == .title ? (viewModel.sortAscending ? "↑" : "↓") : "")")) {
                        if viewModel.sortOption == .title {
                            viewModel.sortAscending.toggle()
                        } else {
                            viewModel.sortOption = .title
                            viewModel.sortAscending = true
                        }
                    },
                    .cancel(Text("取消"))
                ])
            }
            .dismissKeyboardOnTap()
        }
    }
}

// MARK: - SearchBar
struct SearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 17))
                
                TextField("搜索待办事项...", text: $text)
                    .font(.system(size: 17))
                    .focused($isFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        isFocused = false
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("完成") {
                                isFocused = false
                            }
                        }
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        withAnimation {
                            text = ""
                            isFocused = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 17))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Color.white
                    .cornerRadius(13)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            )
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - BackgroundColorPicker
struct BackgroundColorPicker: View {
    @Binding var selectedColor: Color
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(TodoListViewModel.predefinedColors, id: \.name) { colorOption in
                    ColorOptionCard(
                        name: colorOption.name,
                        color: colorOption.color,
                        isSelected: selectedColor == colorOption.color
                    ) {
                        withAnimation {
                            selectedColor = colorOption.color
                            dismiss()
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - CardColorPicker
struct CardColorPicker: View {
    @Binding var selectedColor: Color
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(TodoListViewModel.predefinedCardColors, id: \.name) { colorOption in
                    ColorOptionCard(
                        name: colorOption.name,
                        color: colorOption.color,
                        isSelected: selectedColor == colorOption.color
                    ) {
                        withAnimation {
                            selectedColor = colorOption.color
                            dismiss()
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct ColorOptionCard: View {
    let name: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                    )
                    .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 2)
                
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                }
            }
            .padding(8)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - TodoRowView
/// 单个待办事项的视图
struct TodoRowView: View {
    // MARK: Properties
    let todo: TodoItem
    let onToggle: () -> Void
    let onEdit: () -> Void
    let mainBlue: Color
    @ObservedObject var viewModel: TodoListViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 15) {
                // 完成状态切换按钮
                ZStack {
                    Circle()
                        .stroke(todo.isCompleted ? mainBlue : Color(red: 0.7, green: 0.7, blue: 0.7), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if todo.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(mainBlue)
                    }
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onToggle()
                    }
                }
                
                // 待办事项内容
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        // 标题
                        Text(todo.title)
                            .font(.custom("PingFangSC-Semibold", size: 18))
                            .strikethrough(todo.isCompleted)
                            .foregroundColor(todo.isCompleted ? Color.gray.opacity(0.6) : Color(red: 0.2, green: 0.2, blue: 0.3))
                        
                        // 优先级标签
                        if !todo.isCompleted {
                            Circle()
                                .fill(getPriorityColor(todo.priority))
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    // 备注（如果有）
                    if let notes = todo.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.custom("PingFangSC-Regular", size: 15))
                            .foregroundColor(Color.gray.opacity(0.8))
                            .lineLimit(2)
                            .lineSpacing(2)
                    }
                    
                    // 底部信息栏
                    HStack(spacing: 12) {
                        // 截止日期（如果有）
                        if let dueDate = todo.dueDate {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 13))
                                Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.custom("PingFangSC-Regular", size: 13))
                            }
                            .foregroundColor(isDueDateOverdue(dueDate) ? 
                                Color(red: 0.95, green: 0.3, blue: 0.3) : 
                                Color(red: 0.3, green: 0.6, blue: 0.95))
                        }
                        
                        // 标签（如果有）
                        if !todo.tags.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "tag")
                                    .font(.system(size: 13))
                                Text(todo.tags.joined(separator: ", "))
                                    .font(.custom("PingFangSC-Regular", size: 13))
                                    .lineLimit(1)
                            }
                            .foregroundColor(Color.gray.opacity(0.7))
                        }
                    }
                    .padding(.top, 2)
                }
                .onTapGesture {
                    onEdit()
                }
                
                Spacer()
            }
            
            
            // 图片（如果有）
            if let imageData = todo.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        // 卡片样式
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(viewModel.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
        )
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper Methods
    /// 检查截止日期是否已过期
    private func isDueDateOverdue(_ date: Date) -> Bool {
        date < Date()
    }
    
    /// 获取优先级对应的颜色
    private func getPriorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .high:
            return Color.red.opacity(0.8)
        case .medium:
            return Color.orange.opacity(0.8)
        case .low:
            return Color.blue.opacity(0.8)
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}

// MARK: - UUID + Identifiable
extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}

// MARK: - View Extensions
extension View {
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                         to: nil, 
                                         from: nil, 
                                         for: nil)
        }
    }
}
