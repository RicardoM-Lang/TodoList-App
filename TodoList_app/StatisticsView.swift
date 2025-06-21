import SwiftUI

struct StatisticsView: View {
    @ObservedObject var viewModel: TodoListViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 总任务数卡片
                StatCard(
                    title: "总任务数",
                    value: "\(viewModel.statistics.total)",
                    icon: "checklist",
                    color: .blue
                )
                
                // 已完成任务卡片
                StatCard(
                    title: "已完成",
                    value: "\(viewModel.statistics.completed)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                // 待完成任务卡片
                StatCard(
                    title: "待完成",
                    value: "\(viewModel.statistics.total - viewModel.statistics.completed)",
                    icon: "circle",
                    color: .orange
                )
                
                // 已逾期任务卡片
                StatCard(
                    title: "已逾期",
                    value: "\(viewModel.statistics.overdue)",
                    icon: "exclamationmark.circle.fill",
                    color: .red
                )
                
                // 即将到期任务卡片
                StatCard(
                    title: "即将到期",
                    value: "\(viewModel.statistics.upcoming)",
                    icon: "clock.fill",
                    color: .purple
                )
            }
            .padding()
        }
        .navigationTitle("统计")
        .background(Color(.systemGroupedBackground))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            // 图标区域
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    NavigationView {
        StatisticsView(viewModel: TodoListViewModel())
    }
} 