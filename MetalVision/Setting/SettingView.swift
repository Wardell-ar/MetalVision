//
//  SettingView.swift
//  MetalVision
//
//  Created by 吴泓霖 on 2024/11/30.
//

import SwiftUI

struct SettingView: View {
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @State private var selectedAppIcon: String = "Default"
    @State private var showAlert: Bool = false
    @State private var isWeChatActive: Bool // 根据设备类型初始化

    // 初始化方法
    init() {
        // 判断设备类型
        _isWeChatActive = State(initialValue: UIDevice.current.userInterfaceIdiom == .pad)
    }
    let appIcons = ["Default", "Halloween"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("外观")) {
                    Toggle("暗黑模式", isOn: $isDarkMode)
                        .onChange(of: isDarkMode) {
                            updateUserInterfaceStyle()
                        }
                
                    Picker("应用图标", selection: $selectedAppIcon) {
                        ForEach(appIcons, id: \.self) { icon in
                            Text(icon)
                        }
                    }
                    .onChange(of: selectedAppIcon) { oldValue,newValue in
                        changeAppIcon(to: newValue)
                    }
                }
                
                Section(header: Text("About")) {
                    Link("技术支持", destination: URL(string: "https://developer.apple.com/cn/metal")!)
                    Button("前往App Store评分") {
                        showAlert = true
                    }
                }
                
                Section(header: Text("开发相关")) {
//                    NavigationLink {
//                        WeChat()
//                    } label: {
//                        Text("打赏开发者")
//                    }
                    NavigationLink(destination: WeChat(), isActive: $isWeChatActive) {
                                          Text("打赏开发者")
                                      }
                    
                    Text("版本: 1.0.0")
                    
                }
            }
            .navigationTitle("设置")
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("打个五星好评吧"), message: Text("☆☆☆☆☆"), dismissButton: .default(Text("OK")))
        }
    }
    
    // 更改 App 图标
    private func changeAppIcon(to iconName: String) {
        let iconToSet = (iconName == "Default") ? nil : iconName
        UIApplication.shared.setAlternateIconName(iconToSet) { error in
            if let error = error {
                print("Error changing app icon: \(error.localizedDescription)")
            }
        }
    }
    private func updateUserInterfaceStyle() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
            }
        }
    }
}

#Preview {
    SettingView()
}
