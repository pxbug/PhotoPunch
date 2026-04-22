import SwiftUI

struct SettingsView: View {
    // 用户设置
    @AppStorage("imageQuality") private var imageQuality: Double = 0.9
    @AppStorage("autoSaveToAlbum") private var autoSaveToAlbum: Bool = false
    @AppStorage("showProcessingDetails") private var showProcessingDetails: Bool = true
    
    @State private var showingClearCacheAlert = false
    @State private var showingAbout = false
    @State private var cacheSize: String = "计算中..."
    
    var body: some View {
        NavigationView {
            List {
                // 图片设置
                Section(header: Text("图片设置")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("图片质量")
                            Spacer()
                            Text("\(Int(imageQuality * 100))%")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $imageQuality, in: 0.5...1.0, step: 0.1)
                            .accentColor(.blue)
                    }
                    .padding(.vertical, 4)
                    
                    Toggle("自动保存到相册", isOn: $autoSaveToAlbum)
                    
                    Toggle("显示处理详情", isOn: $showProcessingDetails)
                }
                
                // 存储管理
                Section(header: Text("存储管理")) {
                    HStack {
                        Text("缓存大小")
                        Spacer()
                        Text(cacheSize)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        showingClearCacheAlert = true
                    }) {
                        HStack {
                            Text("清除缓存")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
                
                // 关于应用
                Section(header: Text("关于")) {
                    HStack {
                        Text("应用名称")
                        Spacer()
                        Text("抠抠图")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        showingAbout = true
                    }) {
                        HStack {
                            Text("关于抠抠图")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Button(action: {
                        if let url = URL(string: "https://github.com/yourusername/PhotoPunch") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text("GitHub")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
                
                // 隐私与支持
                Section(header: Text("隐私与支持")) {
                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text("隐私设置")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Button(action: {
                        // 打开反馈邮件
                        if let url = URL(string: "mailto:support@photopunch.app?subject=抠抠图反馈") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text("反馈与建议")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                calculateCacheSize()
            }
            .alert("清除缓存", isPresented: $showingClearCacheAlert) {
                Button("取消", role: .cancel) { }
                Button("清除", role: .destructive) {
                    clearCache()
                }
            } message: {
                Text("确定要清除所有缓存吗？此操作无法撤销。")
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
    
    // 计算缓存大小
    private func calculateCacheSize() {
        DispatchQueue.global(qos: .background).async {
            let fileManager = FileManager.default
            var totalSize: Int64 = 0
            
            // 获取缓存目录
            if let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
                if let files = try? fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: [.fileSizeKey]) {
                    for file in files {
                        if let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                            totalSize += Int64(fileSize)
                        }
                    }
                }
            }
            
            let sizeString = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
            
            DispatchQueue.main.async {
                cacheSize = sizeString
            }
        }
    }
    
    // 清除缓存
    private func clearCache() {
        let fileManager = FileManager.default
        
        if let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            if let files = try? fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil) {
                for file in files {
                    try? fileManager.removeItem(at: file)
                }
            }
        }
        
        // 重新计算缓存大小
        calculateCacheSize()
    }
}

// 关于页面
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo 和应用名
                    VStack(spacing: 12) {
                        Image(systemName: "scissors.badge.ellipsis")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("抠抠图")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("版本 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // 应用介绍
                    VStack(alignment: .leading, spacing: 16) {
                        Text("关于抠抠图")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("抠抠图是一款专业的智能抠图应用，采用先进的AI技术，能够快速准确地识别并抠取图片中的主体。无论是人物、动物还是物品，都能轻松完成抠图。")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                        
                        Divider()
                        
                        Text("主要功能")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            FeatureRow(icon: "wand.and.stars", title: "智能识别", description: "AI自动识别图片主体")
                            FeatureRow(icon: "bolt.fill", title: "快速处理", description: "3秒完成抠图")
                            FeatureRow(icon: "paintbrush.fill", title: "背景替换", description: "多种背景可选")
                            FeatureRow(icon: "square.and.arrow.down", title: "一键保存", description: "快速保存到相册")
                        }
                        
                        Divider()
                        
                        Text("联系我们")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("邮箱: support@photopunch.app")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Text("网站: www.photopunch.app")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // 版权信息
                    Text("© 2025 抠抠图. All rights reserved.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 功能行组件
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
} 