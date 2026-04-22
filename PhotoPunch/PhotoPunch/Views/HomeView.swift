import SwiftUI

struct HomeView: View {
    @State private var breathingScale: CGFloat = 1.0
    @State private var showMatteView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("高质量的智能抠图")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 15)
                    
                    // 状态指示器
                    HStack {
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 10, height: 10)
                                .scaleEffect(breathingScale)
                                .shadow(color: Color.green.opacity(0.5), radius: 2 * breathingScale)
                                .onAppear {
                                    withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                        breathingScale = 1.3
                                    }
                                }
                            
                            Text("抠图模型 v3.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(UIColor.systemGray6))
                        )
                        
                        Spacer()
                    }
                    .padding(.bottom, -5)
                    
                    VStack(spacing: 6) {
                        Text("更新时间：2025年9月03日 16:00")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("修复处理图效率问题，提高图片处理清晰度，如果使用遇到问题请找我们反馈。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            if let url = URL(string: "https://qm.qq.com/q/5L1kIl6CWc") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("欢迎加入产品沟通群反馈意见")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .underline()
                        }
                        .padding(.top, 2)
                    }
                    
                    Image("抠图")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        .padding(.top, 5)
                    
                    VStack(spacing: 8) {
                        Text("全自动智能抠图")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("支持所有场景的图片抠图，全程自动3秒即可抠好一张图")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        showMatteView = true
                    }) {
                        Text("立即抠图")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Color.blue)
                            .cornerRadius(25)
                    }
                    .padding(.top, 5)
                    
                    // 常见问题部分
                    VStack(alignment: .leading, spacing: 12) {
                        Text("常见问题")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                        
                        ExpandableFAQItem(question: "抠图是真正的免费吗？", 
                                answer: "是的，抠抠图就是一个专门做免费抠图的应用程序，免费抠图没有套路没有付费。")
                        
                        Divider()
                        
                        ExpandableFAQItem(question: "下载的图片有没有水印？", 
                                answer: "没有水印，可以免费下载无水印高清图。")
                        
                        Divider()
                        
                        ExpandableFAQItem(question: "我上传的图片安不安全？", 
                                answer: "我们对上传的图片是进行加密处理的，图片上传后10分钟程序会自动清除预览图像以及结果图像，不会做历史存留，请及时保存图片。")
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("PhotoPunch")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: $showMatteView) {
                MatteView()
            }
        }
    }
}

struct ExpandableFAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(question)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                Text(answer)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 3)
                    .transition(.opacity)
            }
        }
    }
}

#Preview {
    HomeView()
} 