//
//  ContentView.swift
//  WSR
//
//  Created by 吴泓霖 on 2024/11/27.
//

import SwiftUI

struct ContentView: View {
    @State private var photoModel = PhotoModel()
    @State private var videoModel = VideoModel()
    @AppStorage("isIntroFinished")  private var isIntroFinished=false
    @State private var selectedTab = 0 // 当前选中的Tab
    
    
   
    var body: some View {
       
        ZStack{
            if(isIntroFinished){
                TabView (selection: $selectedTab){
                    IntroView()
                        .tabItem {Label("首页", systemImage: "house")}
                        .tag(0)
                    PhotoView()
                        .tabItem {Label("照片超分", systemImage: "photo")}
                        .tag(1)
                        .environment(photoModel)
                    VideoView()
                        .tabItem {Label("视频超分", systemImage: "video")}
                        .tag(2)
                        .environment(videoModel)
                    SettingView()
                        .tabItem {Label("设置", systemImage: "gear")}
                        .tag(3)
                    
                }
                .onChange(of: selectedTab) {
//                    photoModel.clearPhoto()
//                    videoModel.clearVideo()
                }
            }
            else{
                IntroView()
            }
        }
        .accentColor(.pink.opacity(0.7))
    }
      
}

#Preview {
    ContentView()
}
