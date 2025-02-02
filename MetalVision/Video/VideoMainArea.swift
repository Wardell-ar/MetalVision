//
//  VideoNav.swift
//  MetalVision
//
//  Created by 吴泓霖 on 2024/12/1.
//

import SwiftUI
import UIKit
import AVFoundation
import AVKit
struct VideoPlayerRepresentable: UIViewControllerRepresentable {
    let player : AVPlayer?

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerController = AVPlayerViewController()
        playerController.player = player
        playerController.showsPlaybackControls = true
        return playerController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
    }
}
struct VideoMainArea: View {
    @Environment(VideoModel.self) private var videoModel
   
    var body: some View {
        @Bindable var videoModel=videoModel
        VStack {
            ZStack(alignment: .center) {
                if let inputPlayer = videoModel.inputPlayer{
                    if let outputPlayer = videoModel.outputPlayer {
                        //GeometryReader { geometry in
                        if videoModel.checkingPrevious{
                            VideoPlayerRepresentable(player: inputPlayer)
                                .contextMenu {
                                    Button(action: {
                                          videoModel.showShareSheet = true
                                                                        }) {
                                        Label("分享视频", systemImage: "square.and.arrow.up")
                                    }
                                    
                                    Button(action: {
                                       
                                            videoModel.saveVideo()
                                        
                                    }) {
                                        Label("保存视频", systemImage: "square.and.arrow.down")
                                    }
                                    .alert(isPresented: $videoModel.showAlert) {  // 使用绑定状态来控制 Alert 显示
                                        Alert( title: Text("提示"),
                                               message: Text("视频已保存到相册"),
                                               dismissButton: .default(Text("确定")))
                                    }
                                    
                                    Button(role: .destructive, action: {
                                        videoModel.clearVideo()
                                    }) {
                                        Label("重新选择", systemImage: "arrow.clockwise")
                                    }
                                }
                              
                        }else{
                            // 修复后
                            VideoPlayerRepresentable(player: outputPlayer)
                                .contextMenu {
                                    Button(action: {
                                          videoModel.showShareSheet = true
                                                                        }) {
                                        Label("分享视频", systemImage: "square.and.arrow.up")
                                    }
                                    
                                    Button(action: {
                                       
                                            videoModel.saveVideo()
                                        
                                    }) {
                                        Label("保存视频", systemImage: "square.and.arrow.down")
                                    }
                                    .alert(isPresented: $videoModel.showAlert) {  // 使用绑定状态来控制 Alert 显示
                                        Alert( title: Text("提示"),
                                               message: Text("视频已保存到相册"),
                                               dismissButton: .default(Text("确定")))
                                    }
                                    
                                    Button(role: .destructive, action: {
                                        videoModel.clearVideo()
                                    }) {
                                        Label("重新选择", systemImage: "arrow.clockwise")
                                    }
                                }
                               
                                
                        }
                        
                        //}
                    } else {
                        VideoPlayerRepresentable(player: inputPlayer)
                            .contextMenu {
                                Button(action: {
                                      videoModel.showShareSheet = true
                                                                    }) {
                                    Label("分享视频", systemImage: "square.and.arrow.up")
                                }
                                
                                Button(action: {
                                   
                                        videoModel.saveVideo()
                                    
                                }) {
                                    Label("保存视频", systemImage: "square.and.arrow.down")
                                }
                                .alert(isPresented: $videoModel.showAlert) {  // 使用绑定状态来控制 Alert 显示
                                    Alert( title: Text("提示"),
                                           message: Text("视频已保存到相册"),
                                           dismissButton: .default(Text("确定")))
                                }
                                
                                Button(role: .destructive, action: {
                                    videoModel.clearVideo()
                                }) {
                                    Label("重新选择", systemImage: "arrow.clockwise")
                                }
                            }
                        
                    }
                }else {
                    Text("请点击下方按钮选择你的视频")
                }
            }
            ProgressView(value: videoModel.currentProgress, total: 1.0)
                .padding()
 
        }

    }

    
}

#Preview {
    VideoMainArea()
        .environment(VideoModel())
}
