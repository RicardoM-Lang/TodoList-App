import SwiftUI
import PhotosUI

struct AddTodoView: View {
    @Binding var isPresented: Bool
    let onAdd: (String, Date?, String?, UIImage?, [String], Priority) -> Void
    let mainBlue: Color
    @EnvironmentObject private var notificationManager: NotificationManager
    
    @State private var title = ""
    @State private var notes = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var tags = ""
    @State private var priority: Priority = .medium
    @State private var showNotificationAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("基本信息")) {
                TextField("标题", text: $title)
                TextField("备注", text: $notes)
                TextField("标签（用逗号分隔）", text: $tags)
            }
            
            Section(header: Text("优先级")) {
                Picker("优先级", selection: $priority) {
                    ForEach(Priority.allCases, id: \.self) { priority in
                        Label(priority.rawValue, systemImage: priority.icon)
                            .foregroundColor(priority.color)
                            .tag(priority)
                    }
                }
            }
            
            Section(header: Text("截止日期")) {
                Toggle("设置截止日期", isOn: $hasDueDate)
                if hasDueDate {
                    DatePicker("截止日期",
                             selection: $dueDate,
                             displayedComponents: [.date, .hourAndMinute])
                }
            }
            
            Section(header: Text("图片")) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipped()
                }
                
                Button(action: {
                    showImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "photo")
                        Text(selectedImage == nil ? "添加图片" : "更换图片")
                    }
                }
                
                if selectedImage != nil {
                    Button(action: {
                        selectedImage = nil
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("删除图片")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("新建待办事项")
        .navigationBarItems(
            leading: Button("取消") {
                isPresented = false
            },
            trailing: Button("添加") {
                if hasDueDate && !notificationManager.isAuthorized {
                    showNotificationAlert = true
                } else {
                    addTodo()
                }
            }
            .disabled(title.isEmpty)
        )
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .alert("需要通知权限", isPresented: $showNotificationAlert) {
            Button("取消", role: .cancel) { }
            Button("去设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("要设置截止日期提醒，需要允许应用发送通知。是否前往设置？")
        }
    }
    
    private func addTodo() {
        let tagArray = tags.split(separator: ",").map(String.init)
        onAdd(title, hasDueDate ? dueDate : nil, notes.isEmpty ? nil : notes, selectedImage, tagArray, priority)
        isPresented = false
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        AddTodoView(isPresented: .constant(true), onAdd: { _, _, _, _, _, _ in }, mainBlue: Color(red: 0.2, green: 0.5, blue: 0.9))
    }
} 
