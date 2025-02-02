//
//  OriginalImage.swift
//  MetalVision
//
//  Created by 吴泓霖 on 2024/11/30.
//

import SwiftUI

struct ImageToShow: View {
    @Environment(PhotoModel.self) private var photoModel
    
    var imageToSHow: UIImage?
    
    var body: some View {
        @Bindable var photoModel = photoModel
        
        Image(uiImage: imageToSHow!)
            .resizable()
            .scaledToFit()
            .contextMenu {
                Button(action: {
                    if let image = imageToSHow {
                        photoModel.fileURLToShare = saveImageWithFileName(image: image, fileName: "MetalVision.png")//把图片打包为临时文件，用于传递给ShareSheet
                        
                        photoModel.showShareSheet = true
                    }
                }) {
                    Label("分享图片", systemImage: "square.and.arrow.up")
                }
                
                Button(action: {
                    if let image = imageToSHow {
                        photoModel.saveImage(image)
                    }
                }) {
                    Label("保存图片", systemImage: "square.and.arrow.down")
                }
                .alert(isPresented: $photoModel.showAlert) {  // 使用绑定状态来控制 Alert 显示
                    Alert( title: Text("提示"),
                           message: Text("图片已保存到相册"),
                           dismissButton: .default(Text("确定")))
                }
                
                Button(role: .destructive, action: {
                    photoModel.clearPhoto()
                }) {
                    Label("重新选择", systemImage: "arrow.clockwise")
                }
            }
    }
}

#Preview {
    ImageToShow()
        .environment(PhotoModel())
}
