//
//  PhotoMainArea.swift
//  MetalVision
//
//  Created by 吴泓霖 on 2024/11/30.
//

import SwiftUI

struct PhotoMainArea: View {
    @Environment(PhotoModel.self) private var photoModel
    
    var body: some View {
        @Bindable var photoModel = photoModel
        // 图片对比区域
        
        
        VStack {
            ZStack(alignment: .center) {
                if let beforeImage = photoModel.originalImage{
                    if let afterImage = photoModel.upscaledImage {
                        GeometryReader { geometry in
                            TabView(selection: $photoModel.checkingPrevious) {
                                ImageToShow(imageToSHow: beforeImage)
                                    .tag(true)
                                
                                
                                // 修复后图片
                                ImageToShow(imageToSHow: afterImage)
                                    .tag(false)
                                
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height) // 占满可用区域
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // 禁用分页指示器
                            .animation(.easeInOut(duration: 0.4), value: true)
                        }
                    } else {
                        ImageToShow(imageToSHow: beforeImage)
                    }
                }else {
                    Text("请点击下方按钮选择你的图片")
                }
            }
            
            HStack(spacing:4){
                if(photoModel.originalImage != nil){
                    Color(Color.accentColor)
                        .opacity(photoModel.checkingPrevious ? 1 : 0.5)
                        .frame(width: photoModel.checkingPrevious ? 16 : 8,height:8)
                        .animation(.easeInOut(duration: 0.4),value: photoModel.checkingPrevious)
                }
                if(photoModel.upscaledImage != nil){
                    Color(Color.accentColor)
                        .opacity(!photoModel.checkingPrevious ? 1 : 0.5)
                        .frame(width: !photoModel.checkingPrevious ? 16 : 8,height:8)
                        .animation(.easeInOut(duration: 0.4),value: !photoModel.checkingPrevious)
                }
                
            }
            
        }
    }
}



#Preview {
    PhotoMainArea()
        .environment(PhotoModel())
}
