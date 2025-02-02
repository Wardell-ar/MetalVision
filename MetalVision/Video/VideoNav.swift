//
//  VideoNav.swift
//  MetalVision
//
//  Created by 吴泓霖 on 2024/12/1.
//

import SwiftUI

struct VideoNav: View {
    @Environment(VideoModel.self) private var videoModel
    var body: some View {
        @Bindable var videoModel=videoModel
        HStack {
            Text("视频超分")
                .font(.system(size: 20, weight: .bold, design: .default))
                .frame(maxWidth: 80, alignment: .leading)
            
            Spacer()
            
            HStack(spacing: 0) {
               
                Button(action: {
                    withAnimation(.smooth(duration: 0.2)) {
                        videoModel.checkingPrevious = true
                    }
                }) {
                    Text("增强前")
                        .font(.headline)
                        .frame(maxWidth: 80, maxHeight: 40)
                        .background( videoModel.checkingPrevious ? Color.accentColor : Color.white)
                        .foregroundColor( videoModel.checkingPrevious ? .white : .gray)
                        .clipShape(Capsule())
                }
                
                // 右侧按钮（付费游戏）
                Button(action: {
                    withAnimation(.smooth(duration: 0.2)) {
                        videoModel.checkingPrevious = false
                    }
                }) {
                    Text("增强后")
                        .font(.headline)
                        .frame(maxWidth: 80, maxHeight: 40)
                        .background(!videoModel.checkingPrevious ? Color.accentColor : Color.white)
                        .foregroundColor(!videoModel.checkingPrevious ? .white : .gray)
                        .clipShape(Capsule())
                }
                .disabled(videoModel.outputPlayer == nil)
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
                videoModel.showShareSheet = true
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title)
            }
            .sheet(isPresented: $videoModel.showShareSheet) {
                if videoModel.checkingPrevious{
                    if let fileURLToShare = videoModel.inputUrl {
                        ShareSheet(activityItems: [fileURLToShare])
                            .presentationDetents([.fraction(0.5), .large]) // 自定义高度
                    }
                    else {
                        //print("Video at: \(fileURLToShare!)")
                        Text("No content to share\(videoModel.inputUrl)")
                    }
                }else{
                    if let fileURLToShare = videoModel.outputUrl {
                        ShareSheet(activityItems: [fileURLToShare])
                            .presentationDetents([.fraction(0.5), .large]) // 自定义高度
                    }
                    else {
                        //print("Video at: \(fileURLToShare!)")
                        Text("No content to share\(videoModel.outputUrl)")
                    }
                }
            }
            .disabled((videoModel.outputPlayer==nil) || (videoModel.checkingPrevious==true))
            .frame(maxWidth: 80, alignment: .trailing)
        }
        .padding()
       
    }
}

#Preview {
    VideoNav()
        .environment(VideoModel())
}
