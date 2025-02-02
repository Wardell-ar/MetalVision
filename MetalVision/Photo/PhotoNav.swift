//
//  PhotoNav.swift
//  MetalVision
//
//  Created by 吴泓霖 on 2024/11/30.
//

import SwiftUI

struct PhotoNav: View {
    @Environment(PhotoModel.self) private var photoModel
    
    var body: some View {
        @Bindable var photoModel = photoModel
        // 顶部导航栏
        HStack {
            Text("图片超分")
                .font(.system(size: 20, weight: .bold, design: .default))
                .frame(maxWidth: 80, alignment: .leading)
            Spacer()
            
            
            HStack(spacing: 0) {
               
                Button(action: {
                    withAnimation(.smooth(duration: 0.2)) {
                        photoModel.checkingPrevious = true
                    }
                }) {
                    Text("增强前")
                        .font(.headline)
                        .frame(maxWidth: 80, maxHeight: 40)
                        .background( photoModel.checkingPrevious ? Color.accentColor : Color.white)
                        .foregroundColor( photoModel.checkingPrevious ? .white : .gray)
                        .clipShape(Capsule())
                }
                
                // 右侧按钮（付费游戏）
                Button(action: {
                    withAnimation(.smooth(duration: 0.2)) {
                        photoModel.checkingPrevious = false
                    }
                }) {
                    Text("增强后")
                        .font(.headline)
                        .frame(maxWidth: 80, maxHeight: 40)
                        .background(!photoModel.checkingPrevious ? Color.accentColor : Color.white)
                        .foregroundColor(!photoModel.checkingPrevious ? .white : .gray)
                        .clipShape(Capsule())
                }
                .disabled(photoModel.upscaledImage == nil)
            }
            .frame(height: 40,alignment: .center)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.accentColor, lineWidth: 2) // 添加蓝色边框，设置边框宽度
            )
            .padding(.horizontal)
            
            
            Spacer()
            
            // 分享按钮
            Button(action: {
                if let image = photoModel.upscaledImage {
                    photoModel.fileURLToShare = saveImageWithFileName(image: image, fileName: "MetalVision.png")//把图片打包为临时文件，用于传递给ShareSheet
                    
                    photoModel.showShareSheet = true
                }
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title)
            }
            .sheet(isPresented: $photoModel.showShareSheet) {
                if let fileURLToShare:URL = photoModel.fileURLToShare {
                    ShareSheet(activityItems: [fileURLToShare])
                        .presentationDetents([.fraction(0.5), .large]) // 自定义高度
                }
                else {
                    //print("Image at: \(fileURLToShare!)")
                    Text("No content to share\(photoModel.fileURLToShare!)")
                }
            }
            .disabled((photoModel.upscaledImage==nil) || (photoModel.checkingPrevious==true))
            .frame(maxWidth: 80, alignment: .trailing)
            
        }
        .padding()
        
    }
}

#Preview {
    PhotoNav()
        .environment(PhotoModel())
}
