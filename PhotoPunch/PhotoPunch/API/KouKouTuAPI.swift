import Foundation
import UIKit

enum APIError: Error {
    case invalidImage
    case networkError(Error)
    case invalidResponse
    case requestFailed(Int, String)
    case decodingError(Error)
    case taskNotCompleted
    
    var localizedDescription: String {
        switch self {
        case .invalidImage:
            return "无效的图片格式或大小"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .invalidResponse:
            return "服务器返回无效响应"
        case .requestFailed(let code, let message):
            return "请求失败: 错误码 \(code), \(message)"
        case .decodingError(let error):
            return "数据解析错误: \(error.localizedDescription)"
        case .taskNotCompleted:
            return "任务尚未完成，请稍后再试"
        }
    }
}

struct CreateTaskResponse: Codable {
    let code: Int
    let message: String
    let data: TaskData
    
    struct TaskData: Codable {
        let task_id: Int
    }
}

struct QueryTaskResponse: Codable {
    let code: Int
    let message: String
    let data: ResultData
    
    struct ResultData: Codable {
        let state: Int
        let result_file: String?
    }
}

class KouKouTuAPI {
    static let shared = KouKouTuAPI()
    
    private let apiKey = "CRq5GOvc3S6C6ZmdOrgMyewzG4zB10Ji"
    private let createEndpoint = "https://async.koukoutu.com/v1/create"
    private let queryEndpoint = "https://async.koukoutu.com/v1/query"
    
    private init() {}
    
    // 提交抠图任务
    func submitTask(image: UIImage, outputFormat: String = "webp", crop: Int = 0, border: Int = 0, stampCrop: Int = 0) async throws -> Int {
        guard let imageData = image.jpegData(compressionQuality: 0.9) ?? image.pngData() else {
            throw APIError.invalidImage
        }
        
        // 检查图片大小限制 (40MB)
        let maxSize: Int = 40 * 1024 * 1024
        if imageData.count > maxSize {
            throw APIError.invalidImage
        }
        
        // 创建multipart/form-data请求
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: createEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // 添加model_key参数
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model_key\"\r\n\r\n".data(using: .utf8)!)
        body.append("background-removal\r\n".data(using: .utf8)!)
        
        // 添加output_format参数
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"output_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(outputFormat)\r\n".data(using: .utf8)!)
        
        // 添加crop参数
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"crop\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(crop)\r\n".data(using: .utf8)!)
        
        // 添加border参数
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"border\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(border)\r\n".data(using: .utf8)!)
        
        // 添加stamp_crop参数
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"stamp_crop\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(stampCrop)\r\n".data(using: .utf8)!)
        
        // 添加图片文件
        let filename = "image.\(outputFormat == "webp" ? "jpg" : outputFormat)"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image_file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // 结束boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                throw APIError.requestFailed(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "Unknown error")
            }
            
            let decoder = JSONDecoder()
            let createResponse = try decoder.decode(CreateTaskResponse.self, from: data)
            
            if createResponse.code != 200 {
                throw APIError.requestFailed(createResponse.code, createResponse.message)
            }
            
            return createResponse.data.task_id
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // 查询任务状态
    func queryTask(taskId: Int) async throws -> String {
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: queryEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // 添加task_id参数
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"task_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(taskId)\r\n".data(using: .utf8)!)
        
        // 添加response参数
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response\"\r\n\r\n".data(using: .utf8)!)
        body.append("url\r\n".data(using: .utf8)!)
        
        // 结束boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                throw APIError.requestFailed(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "Unknown error")
            }
            
            let decoder = JSONDecoder()
            let queryResponse = try decoder.decode(QueryTaskResponse.self, from: data)
            
            if queryResponse.code != 200 {
                throw APIError.requestFailed(queryResponse.code, queryResponse.message)
            }
            
            // 检查任务状态，state=1表示已完成
            if queryResponse.data.state != 1 {
                throw APIError.taskNotCompleted
            }
            
            guard let resultFile = queryResponse.data.result_file else {
                throw APIError.invalidResponse
            }
            
            return resultFile
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // 下载处理后的图片
    func downloadImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidResponse
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw APIError.invalidResponse
            }
            
            guard let image = UIImage(data: data) else {
                throw APIError.invalidResponse
            }
            
            return image
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // 完整的抠图流程：提交任务 -> 轮询结果 -> 下载图片
    func removeBackground(from image: UIImage, outputFormat: String = "webp", crop: Int = 0, border: Int = 0, stampCrop: Int = 0) async throws -> UIImage {
        // 1. 提交抠图任务
        let taskId = try await submitTask(
            image: image,
            outputFormat: outputFormat,
            crop: crop,
            border: border,
            stampCrop: stampCrop
        )
        
        // 2. 轮询任务结果，最多尝试30次，每次间隔1秒
        var resultUrl: String?
        var attempts = 0
        
        while attempts < 30 {
            do {
                resultUrl = try await queryTask(taskId: taskId)
                break
            } catch APIError.taskNotCompleted {
                // 任务尚未完成，等待1秒后重试
                try await Task.sleep(nanoseconds: 1_000_000_000)
                attempts += 1
            } catch {
                throw error
            }
        }
        
        if resultUrl == nil {
            throw APIError.taskNotCompleted
        }
        
        // 3. 下载处理后的图片
        return try await downloadImage(from: resultUrl!)
    }
}

// Data扩展，用于构建multipart/form-data请求
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
} 