//
//  PhotoTail.swift
//  MetalVision
//
//  Created by 吴泓霖 on 2024/11/30.
//

import SwiftUI

struct ToastView: View {
    @Binding var isShowing: Bool
    var message: String

    var body: some View {
        if isShowing {
            VStack {
                Spacer()
                Text(message)
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeInOut, value: isShowing)
        }
    }
}


struct PhotoTail: View {
    @Environment(PhotoModel.self) private var photoModel
    
    let gradientStart = Color(red: 255.0 / 255, green: 120.0 / 255, blue: 221.0 / 255)
    let gradientEnd = Color.purple//Color(red: 239.0 / 255, green: 172.0 / 255, blue: 120.0 / 255)
    
    var body: some View {
        @Bindable var photoModel = photoModel
        HStack{
            Button(action: {
                photoModel.clearPhoto()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.title)
                    .foregroundColor(.accentColor)
            }
            .frame(maxWidth:80,alignment: .leading)
            Spacer()
            ZStack{
                if(photoModel.originalImage==nil || ((photoModel.checkingPrevious == true) && photoModel.upscaledImage != nil)){
                    Button {
                        photoModel.chooseImage()
                    } label: {
                        ZStack{
                            Rectangle()
                                .fill(Color.blue)
                                .frame(maxWidth: 200,maxHeight: 55)
                                .cornerRadius(12) // 可选：添加圆角
                            Text("选择图片")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    
                    
                    
                }else if(photoModel.upscaledImage==nil){
                    Button {
                        if let image = photoModel.originalImage {
                            photoModel.processImage(image)
                            photoModel.checkingPrevious = false
                        }
                    } label: {
                        ZStack{
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [gradientStart, gradientEnd]), // 渐变的颜色数组
                                        startPoint: .topLeading, // 渐变的起始点
                                        endPoint: .bottomTrailing // 渐变的结束点
                                    )
                                )
                                .frame(maxWidth: 200,maxHeight: 55)
                                .cornerRadius(12) // 可选：添加圆角
                            Text("超分增强")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    
                    
                    
                }else{
                    Button {
                        if let image = photoModel.upscaledImage {
                            photoModel.saveImage(image)
                        }
                    } label: {
                        ZStack{
                            Rectangle()
                                .fill(Color.green)
                                .frame(maxWidth: 200,maxHeight: 55)
                                .cornerRadius(12) // 可选：添加圆角
                            Text("保存图片")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .alert(isPresented: $photoModel.showAlert) {  // 使用绑定状态来控制 Alert 显示
                            Alert( title: Text("提示"),
                                   message: Text("图片已保存到相册"),
                                   dismissButton: .default(Text("确定")))
                        }
                    }
                }
            }
            .frame(maxWidth: 200,alignment:.center)
            Spacer()
            
            
            
            
            Menu {
                Picker("选择", selection: $photoModel.scaleFactor) {
                    Text("高清").tag(Float(1.5))
                    Text("2K").tag(Float(2))
                    Text("4K").tag(Float(3))
                }
                .onChange(of: photoModel.scaleFactor) {oldValue,newValue in
                    if(photoModel.upscaledImage != nil){
                        if let image=photoModel.originalImage{
                            photoModel.processImage(image)
                        }
                        photoModel.checkingPrevious = false
                        photoModel.changeMessage = "已成功重新制作为 \(newValue == 1.5 ? "高清" : newValue == 2 ? "2K" : "4K")图片"
                        photoModel.settingChange = true
                    }
                }
            } label: {
                Text("目标画质")
                    .frame(maxWidth: 80,alignment:.trailing)
                    
            }
            .alert(isPresented:  $photoModel.settingChange) {
                Alert(
                    title: Text("提示"),
                    message: Text(photoModel.changeMessage),
                    dismissButton: .default(Text("确定"))
                )
            }
        
        }
        .padding()
        
    }
}

#Preview {
    PhotoTail()
        .environment(PhotoModel())
}
