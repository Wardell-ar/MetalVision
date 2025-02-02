//
//  ContentView.swift
//  WSR
//
//  Created by 吴泓霖 on 2024/11/27.
//

import SwiftUI
import UIKit

struct OldPhotoView: View {
    @Environment(PhotoModel.self) private var photoModel

    var body: some View {
        @Bindable var photoModel = photoModel
        VStack {
            HStack(spacing: 50) {
                //选择图片
                Button(action: {
                    photoModel.chooseImage()
                })
                {
                    Label("选择", systemImage: "photo.artframe.circle")
                }
                
                
                //处理按钮
                Button(action: {
                    if let image = photoModel.originalImage {
                        photoModel.processImage(image)
                    }
                })
                {
                    Label("超分", systemImage: "star.fill")
                }
                .disabled(photoModel.originalImage == nil)
                
                //保存按钮
                Button(action: {
                    if let image = photoModel.upscaledImage {
                        photoModel.saveImage(image)
                    }
                })
                {
                    Label("保存",systemImage: "square.and.arrow.down") // SF Symbol 图标
                }
                .disabled(photoModel.upscaledImage == nil)
                .alert(isPresented: $photoModel.showAlert) {  // 使用绑定状态来控制 Alert 显示
                    Alert( title: Text("提示"),
                           message: Text("图片已保存到相册"),
                           dismissButton: .default(Text("确定")))
                }
            }
            Divider() // 添加分割线
            
            if photoModel.originalImage != nil{
                HStack(spacing: 20) { // 设置按钮之间的间距
                    Button(action: {
                        photoModel.selectedButton = "高清"
                        photoModel.scaleFactor = 1.5
                        photoModel.upscaledImage = nil

                    }) {
                        Text("高清")
                            .frame(maxWidth: .infinity) // 使按钮宽度自适应
                            .padding()
                            .background(photoModel.selectedButton == "高清" ? Color.accentColor :Color.gray.opacity(0.1))
                            .foregroundColor(photoModel.selectedButton == "高清" ? Color.white :.gray)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        photoModel.selectedButton = "2K"
                        photoModel.scaleFactor = 2
                        photoModel.upscaledImage = nil
                    }) {
                        Text("2K")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(photoModel.selectedButton == "2K" ? Color.accentColor :Color.gray.opacity(0.1))
                            .foregroundColor(photoModel.selectedButton == "2K" ? Color.white :.gray)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        photoModel.selectedButton = "4K"
                        photoModel.scaleFactor = 3
                        photoModel.upscaledImage = nil

                    }) {
                        Text("4K")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(photoModel.selectedButton == "4K" ? Color.accentColor :Color.gray.opacity(0.1))
                            .foregroundColor(photoModel.selectedButton == "4K" ? Color.white :.gray)
                            .cornerRadius(10)
                    }
                }
            }
            
            if photoModel.originalImage == nil{
                Spacer() // 占据顶部的空间
                Text("请选择你想要增强的图片")
                    .font(.largeTitle)
              
            }
            else{
                ScrollView{
                    VStack(spacing: 20) {
                        if let original = photoModel.originalImage {
                            VStack {
                                Text("原始图片")
                                    .font(.headline)
                                Image(uiImage: original)
                                    .resizable()
                                    .scaledToFit()
                                //.frame(maxWidth: 300, maxHeight: 300)
                                    .border(Color.gray, width: 1)
                            }
                        }
                        
                        if let upscaled = photoModel.upscaledImage {
                            
                            VStack {
                                Text("超分图片")
                                    .font(.headline)
                                Image(uiImage: upscaled)
                                    .resizable()
                                    .scaledToFit()
                                    .border(Color.gray, width: 1)
                            }
                        }
                    }
                }
            }
            
            
            Spacer()
            
        }
        .padding()
       
    }

    
}





#Preview {
    OldPhotoView()
        .environment(PhotoModel())
}

