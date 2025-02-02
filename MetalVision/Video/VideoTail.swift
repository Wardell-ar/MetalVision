
//  VideoNav.swift
//  MetalVision
//
//  Created by 吴泓霖 on 2024/12/1.
//

import SwiftUI
import AVKit
struct VideoTail: View {
    @Environment(VideoModel.self) private var videoModel
    let gradientStart = Color(red: 255.0 / 255, green: 120.0 / 255, blue: 221.0 / 255)
    let gradientEnd = Color.purple//Color(red: 239.0 / 255, green: 172.0 / 255, blue: 120.0 / 255)
    
    var body: some View {
        @Bindable var videoModel=videoModel
        HStack{
            Button(action: {
                videoModel.clearVideo()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.title)
                    .foregroundColor(.accentColor)
            }
            .frame(maxWidth:80,alignment: .leading)
            Spacer()
            ZStack{
                if(videoModel.inputPlayer==nil || ((videoModel.checkingPrevious == true) && videoModel.outputPlayer != nil)){
                    Button {
                        //showPicker = true
                        videoModel.chooseVideo()
                    } label: {
                        ZStack{
                            Rectangle()
                                .fill(Color.blue)
                                .frame(maxWidth: 200,maxHeight: 55)
                                .cornerRadius(12) // 可选：添加圆角
                            Text("选择视频")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .alert(isPresented: $videoModel.unsupportedFormat) {  // 使用绑定状态来控制 Alert 显示
                        Alert( title: Text("视频格式不支持"),
                               message: Text("请选择mov或mp4格式的视频"),
                               dismissButton: .default(Text("确定")))
                    }
                    
                    
                }else if(videoModel.outputPlayer == nil){
                    Button {
                        if let inputUrl = videoModel.inputUrl {
                            videoModel.processVideo(inputUrl: inputUrl)
                            videoModel.checkingPrevious = false
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
                    .disabled(videoModel.currentState == .processing)
                    
                    
                    
                }else{
                    Button {
                        videoModel.saveVideo()
                    } label: {
                        ZStack{
                            Rectangle()
                                .fill(Color.green)
                                .frame(maxWidth: 200,maxHeight: 55)
                                .cornerRadius(12) // 可选：添加圆角
                            Text("保存视频")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .alert(isPresented: $videoModel.showAlert) {  // 使用绑定状态来控制 Alert 显示
                            Alert( title: Text("提示"),
                                   message: Text("视频已保存到相册"),
                                   dismissButton: .default(Text("确定")))
                        }
                    }
                }
            }
            .frame(maxWidth: 200,alignment:.center)
            
            Spacer()
     
            Menu {
                Picker("选择", selection: $videoModel.scaleFactor) {
                    Text("高清").tag(Float(1.5))
                    Text("2K").tag(Float(2))
                    Text("4K").tag(Float(3))
                }
                .onChange(of: videoModel.scaleFactor) {oldValue,newValue in
                    if(videoModel.outputPlayer != nil){
                        if let inputUrl=videoModel.inputUrl{
                            videoModel.clearVideo()
                            videoModel.inputPlayer=AVPlayer(url: inputUrl)
                            videoModel.processVideo(inputUrl: inputUrl)
                        }
                        videoModel.checkingPrevious = false
                        videoModel.changeMessage = "已成功重新制作为 \(newValue == 1.5 ? "高清" : newValue == 2 ? "2K" : "4K")视频"
                        videoModel.settingChange = true
                    }
                }
            } label: {
                Text("目标画质")
                    .frame(maxWidth: 80,alignment:.trailing)
                    
            }
            .alert(isPresented:  $videoModel.settingChange) {
                Alert(
                    title: Text("提示"),
                    message: Text(videoModel.changeMessage),
                    dismissButton: .default(Text("确定"))
                )
            }
        }
        .padding()
    }
    
}

#Preview {
    VideoTail()
        .environment(VideoModel())
}
