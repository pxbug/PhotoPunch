import SwiftUI
import Photos
import UIKit

// 图片保存工具类，符合iOS原生开发规范
class ImageSaver: NSObject {
    typealias CompletionHandler = (Bool, Error?, String?) -> Void
    
    private var completionHandler: CompletionHandler?
    
    // 保存图片到相册
    func saveImage(_ image: UIImage, completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        
        print("[PhotoPunch Debug] 开始保存图片，图片尺寸: \(image.size), 方向: \(image.imageOrientation.rawValue)")
        
        // 检查相册权限
        checkPhotoLibraryPermission { [weak self] hasPermission, error in
            guard let self = self else { 
                print("[PhotoPunch Debug] self 已被释放，无法继续保存图片")
                return 
            }
            
            if let error = error {
                // 权限检查出错
                print("[PhotoPunch Debug] 权限检查失败: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.completionHandler?(false, error, nil)
                }
                return
            }
            
            print("[PhotoPunch Debug] 权限检查结果: \(hasPermission ? "有权限" : "无权限")")
            
            if hasPermission {
                // 有权限，保存图片
                print("[PhotoPunch Debug] 开始保存图片")
                
                // 检查图片是否有效
                if image.cgImage == nil && image.ciImage == nil {
                    print("[PhotoPunch Debug] 错误: 图片无效 (没有 CGImage 或 CIImage)")
                    let error = NSError(domain: "PhotoPunchErrorDomain", 
                                       code: 500, 
                                       userInfo: [NSLocalizedDescriptionKey: "图片数据无效"])
                    DispatchQueue.main.async {
                        self.completionHandler?(false, error, nil)
                    }
                    return
                }
                
                // 尝试确保图片有有效的CGImage
                let finalImage = self.ensureValidImage(image)
                print("[PhotoPunch Debug] 处理后的图片: 尺寸=\(finalImage.size), 方向=\(finalImage.imageOrientation.rawValue)")
                print("[PhotoPunch Debug] 处理后图片是否有 CGImage: \(finalImage.cgImage != nil)")
                
                // 尝试使用PHPhotoLibrary保存图片
                self.saveImageUsingPhotoLibrary(finalImage)
            } else {
                // 没有权限，返回错误
                print("[PhotoPunch Debug] 没有相册写入权限")
                let error = NSError(domain: "PhotoPunchErrorDomain", 
                                   code: 403, 
                                   userInfo: [NSLocalizedDescriptionKey: "没有保存到相册的权限，请在设置中允许应用访问相册"])
                DispatchQueue.main.async {
                    self.completionHandler?(false, error, nil)
                }
            }
        }
    }
    
    // 使用PHPhotoLibrary保存图片
    private func saveImageUsingPhotoLibrary(_ image: UIImage) {
        print("[PhotoPunch Debug] 尝试使用PHPhotoLibrary保存图片")
        
        // 尝试将图片转换为JPEG数据
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            print("[PhotoPunch Debug] 错误: 无法将图片转换为JPEG数据")
            let error = NSError(domain: "PhotoPunchErrorDomain", 
                               code: 500, 
                               userInfo: [NSLocalizedDescriptionKey: "无法将图片转换为JPEG数据"])
            DispatchQueue.main.async {
                self.completionHandler?(false, error, nil)
            }
            return
        }
        
        print("[PhotoPunch Debug] 成功将图片转换为JPEG数据，大小: \(imageData.count) bytes")
        
        // 使用PHPhotoLibrary保存图片
        PHPhotoLibrary.shared().performChanges({
            // 创建图片请求
            let creationRequest = PHAssetCreationRequest.forAsset()
            // 添加图片数据
            creationRequest.addResource(with: .photo, data: imageData, options: nil)
            
            print("[PhotoPunch Debug] 已提交图片保存请求")
        }, completionHandler: { [weak self] success, error in
            guard let self = self else { return }
            
            if success {
                print("[PhotoPunch Debug] PHPhotoLibrary保存图片成功")
                DispatchQueue.main.async {
                    self.completionHandler?(true, nil, "图片已保存到相册")
                }
            } else {
                print("[PhotoPunch Debug] PHPhotoLibrary保存图片失败")
                if let error = error {
                    print("[PhotoPunch Debug] 错误: \(error.localizedDescription)")
                    
                    if let nsError = error as NSError? {
                        print("[PhotoPunch Debug] 错误域: \(nsError.domain)")
                        print("[PhotoPunch Debug] 错误代码: \(nsError.code)")
                        print("[PhotoPunch Debug] 错误信息: \(nsError.userInfo)")
                    }
                    
                    DispatchQueue.main.async {
                        self.completionHandler?(false, error, nil)
                    }
                } else {
                    print("[PhotoPunch Debug] 未知错误")
                    let error = NSError(domain: "PhotoPunchErrorDomain", 
                                       code: 500, 
                                       userInfo: [NSLocalizedDescriptionKey: "保存图片时发生未知错误"])
                    DispatchQueue.main.async {
                        self.completionHandler?(false, error, nil)
                    }
                }
                
                // 如果PHPhotoLibrary方法失败，尝试使用传统方法
                print("[PhotoPunch Debug] PHPhotoLibrary方法失败，尝试使用传统方法")
                self.saveImageUsingTraditionalMethod(image)
            }
        })
    }
    
    // 使用传统方法保存图片
    private func saveImageUsingTraditionalMethod(_ image: UIImage) {
        print("[PhotoPunch Debug] 尝试使用传统方法保存图片")
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    // 确保图片有有效的CGImage
    private func ensureValidImage(_ image: UIImage) -> UIImage {
        print("[PhotoPunch Debug] 尝试确保图片有有效的CGImage")
        
        // 如果已经有CGImage，直接返回
        if let _ = image.cgImage {
            print("[PhotoPunch Debug] 图片已有CGImage，无需转换")
            return image
        }
        
        // 尝试通过绘制创建新图片
        print("[PhotoPunch Debug] 尝试通过绘制创建新图片")
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        print("[PhotoPunch Debug] 转换后图片是否有CGImage: \(newImage.cgImage != nil)")
        return newImage
    }
    
    // 检查相册权限
    private func checkPhotoLibraryPermission(completion: @escaping (Bool, Error?) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        print("[PhotoPunch Debug] 当前相册权限状态: \(statusToString(status))")
        
        switch status {
        case .authorized, .limited:
            // 已有权限
            print("[PhotoPunch Debug] 已有相册权限")
            completion(true, nil)
        case .notDetermined:
            // 请求权限
            print("[PhotoPunch Debug] 权限未确定，正在请求...")
            PHPhotoLibrary.requestAuthorization { newStatus in
                print("[PhotoPunch Debug] 权限请求结果: \(self.statusToString(newStatus))")
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited, nil)
                }
            }
        case .denied, .restricted:
            // 没有权限
            print("[PhotoPunch Debug] 相册权限被拒绝或受限")
            let error = NSError(domain: "PhotoPunchErrorDomain", 
                               code: 403, 
                               userInfo: [NSLocalizedDescriptionKey: "相册访问权限被拒绝，请在设置中允许应用访问相册"])
            completion(false, error)
        @unknown default:
            print("[PhotoPunch Debug] 未知的权限状态")
            let error = NSError(domain: "PhotoPunchErrorDomain", 
                               code: 500, 
                               userInfo: [NSLocalizedDescriptionKey: "未知的权限状态"])
            completion(false, error)
        }
    }
    
    // 将权限状态转换为字符串，方便调试
    private func statusToString(_ status: PHAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "authorized"
        case .denied: return "denied"
        case .limited: return "limited"
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        @unknown default: return "unknown"
        }
    }
    
    // 图片保存回调
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("[PhotoPunch Debug] 保存图片失败: \(error.localizedDescription)")
            print("[PhotoPunch Debug] 错误详情: \(error)")
            
            // 尝试获取更多错误信息
            if let nsError = error as NSError? {
                print("[PhotoPunch Debug] 错误域: \(nsError.domain)")
                print("[PhotoPunch Debug] 错误代码: \(nsError.code)")
                print("[PhotoPunch Debug] 错误信息: \(nsError.userInfo)")
            }
            
            DispatchQueue.main.async {
                self.completionHandler?(false, error, nil)
            }
        } else {
            print("[PhotoPunch Debug] 图片保存成功")
            
            DispatchQueue.main.async {
                self.completionHandler?(true, nil, "图片已保存到相册")
            }
        }
    }
}

// 原生iOS弹窗管理器
class AlertManager {
    static func showAlert(title: String, message: String, in viewController: UIViewController) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "确定", style: .default))
        viewController.present(alertController, animated: true)
    }
}

// UIViewController表示器，用于在SwiftUI中显示UIKit弹窗
struct UIViewControllerRepresenter: UIViewControllerRepresentable {
    let viewController = UIViewController()
    var onViewControllerReady: ((UIViewController) -> Void)?
    
    func makeUIViewController(context: Context) -> UIViewController {
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        onViewControllerReady?(uiViewController)
    }
}

// 圆形进度条视图
struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // 背景圆环
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // 进度圆环
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    Color.white,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90)) // 从顶部开始
                .frame(width: size, height: size)
                .animation(.easeInOut, value: progress)
        }
    }
}

struct MatteView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var isProcessing = false
    @State private var showImagePicker = false
    @State private var showingSaveSuccess = false
    @State private var showingSaveError = false
    @State private var errorMessage: String = ""
    @State private var showingErrorAlert = false
    @State private var processingProgress: Double = 0
    @State private var processingStatus: String = "正在准备..."
    @State private var rootViewController: UIViewController?
    
    // 添加UIViewControllerRepresenter来获取根视图控制器
    private var viewControllerRepresenter: some View {
        UIViewControllerRepresenter { viewController in
            self.rootViewController = viewController
        }
        .frame(width: 0, height: 0)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if let image = selectedImage {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(16)
                                .shadow(radius: 3)
                                .padding(.horizontal)
                            
                            Button(action: {
                                selectedImage = nil
                                processedImage = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black.opacity(0.6)))
                            }
                            .padding(.top, 8)
                            .padding(.trailing, 24)
                        }
                    } else {
                        VStack(spacing: 15) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 70))
                                .foregroundColor(.gray)
                            
                            Text("选择一张图片进行抠图")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 10)
                            
                            Button(action: {
                                showImagePicker = true
                            }) {
                                Text("选择图片")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 180, height: 45)
                                    .background(Color.blue)
                                    .cornerRadius(22.5)
                                    .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    if let processedImage = processedImage {
                        Text("抠图结果")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        Image(uiImage: processedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(16)
                            .shadow(radius: 3)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    if selectedImage != nil {
                        HStack(spacing: 20) {
                            if processedImage == nil {
                                Button(action: {
                                    processImage()
                                }) {
                                    Text("开始抠图")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Color.blue)
                                        .cornerRadius(25)
                                        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                                }
                                .disabled(isProcessing)
                            } else {
                                Button(action: {
                                    saveImageToGallery()
                                }) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.down")
                                        Text("保存到相册")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.green)
                                    .cornerRadius(25)
                                    .shadow(color: Color.green.opacity(0.3), radius: 5, x: 0, y: 3)
                                }
                                
                                Button(action: {
                                    selectedImage = nil
                                    processedImage = nil
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.counterclockwise")
                                        Text("重新选择")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.blue, lineWidth: 2)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
                
                if isProcessing {
                    ZStack {
                        // 移除背景遮罩
                        VStack(spacing: 12) {
                            // 圆形进度条
                            ZStack {
                                CircularProgressView(
                                    progress: processingProgress,
                                    lineWidth: 4,
                                    size: 60
                                )
                                
                                Text("\(Int(processingProgress * 100))%")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Text(processingStatus)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 180)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.8))
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                }
            }
            .navigationTitle("图片抠图")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(selectedImage: $selectedImage)
            }
            .alert("保存成功", isPresented: $showingSaveSuccess) {
                Button("确定", role: .cancel) { }
            } message: {
                Text("图片已成功保存到相册")
            }
            .alert("保存失败", isPresented: $showingSaveError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("抠图失败", isPresented: $showingErrorAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            // 添加viewControllerRepresenter到视图层次结构中
            .background(viewControllerRepresenter)
        }
    }
    
    private func processImage() {
        guard let selectedImage = selectedImage else { return }
        
        isProcessing = true
        processingProgress = 0.01
        processingStatus = "正在准备..."
        
        // 使用异步API进行抠图
        Task {
            do {
                // 模拟进度更新
                startProgressSimulation()
                
                // 调用抠图API
                let result = try await KouKouTuAPI.shared.removeBackground(from: selectedImage)
                
                // 更新UI
                DispatchQueue.main.async {
                    self.processedImage = result
                    self.isProcessing = false
                    self.processingProgress = 1.0
                }
            } catch let error as APIError {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.errorMessage = error.localizedDescription
                    self.showingErrorAlert = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.errorMessage = "抠图过程中发生未知错误"
                    self.showingErrorAlert = true
                }
            }
        }
    }
    
    private func startProgressSimulation() {
        // 模拟进度更新，因为实际进度无法获取
        Task {
            var progress = 0.01
            let statuses = ["正在准备...", "正在上传图片...", "正在处理图片...", "正在优化边缘...", "正在下载结果..."]
            var statusIndex = 0
            
            while isProcessing && progress < 0.95 {
                // 随机增加进度
                let increment = Double.random(in: 0.01...0.05)
                progress += increment
                
                // 确保进度不超过0.95
                progress = min(progress, 0.95)
                
                // 每隔一段时间更新状态文本
                if progress > Double(statusIndex + 1) * 0.2 && statusIndex < statuses.count - 1 {
                    statusIndex += 1
                }
                
                // 更新UI
                DispatchQueue.main.async {
                    self.processingProgress = progress
                    self.processingStatus = statuses[statusIndex]
                }
                
                // 等待一小段时间
                try? await Task.sleep(nanoseconds: UInt64(0.2 * 1_000_000_000))
            }
        }
    }
    
    private func saveImageToGallery() {
        guard let processedImage = processedImage else { 
            print("[PhotoPunch Debug] 错误: processedImage 为 nil")
            return 
        }
        
        print("[PhotoPunch Debug] 开始保存图片到相册")
        print("[PhotoPunch Debug] 图片信息: 尺寸=\(processedImage.size), 方向=\(processedImage.imageOrientation.rawValue)")
        print("[PhotoPunch Debug] 图片是否有 CGImage: \(processedImage.cgImage != nil)")
        print("[PhotoPunch Debug] 图片是否有 CIImage: \(processedImage.ciImage != nil)")
        
        let imageSaver = ImageSaver()
        imageSaver.saveImage(processedImage) { success, error, message in
            DispatchQueue.main.async {
                if success {
                    print("[PhotoPunch Debug] 图片保存成功，显示成功提示")
                    
                    // 使用原生iOS弹窗提示
                    if let rootVC = self.rootViewController {
                        AlertManager.showAlert(
                            title: "保存成功",
                            message: message ?? "图片已保存到相册",
                            in: rootVC
                        )
                    }
                } else {
                    print("[PhotoPunch Debug] 图片保存失败")
                    if let error = error {
                        print("[PhotoPunch Debug] 错误信息: \(error.localizedDescription)")
                        self.errorMessage = error.localizedDescription
                        
                        // 使用原生iOS弹窗提示错误
                        if let rootVC = self.rootViewController {
                            AlertManager.showAlert(
                                title: "保存失败",
                                message: error.localizedDescription,
                                in: rootVC
                            )
                        }
                    } else {
                        print("[PhotoPunch Debug] 未知错误")
                        self.errorMessage = "保存图片失败"
                        
                        // 使用原生iOS弹窗提示错误
                        if let rootVC = self.rootViewController {
                            AlertManager.showAlert(
                                title: "保存失败",
                                message: "保存图片失败",
                                in: rootVC
                            )
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    MatteView()
} 