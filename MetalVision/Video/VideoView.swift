//
//  Video.swift
//  WSR
//
//  Created by 吴泓霖 on 2024/11/28.
//

import SwiftUI

struct VideoView: View {
    @Environment(VideoModel.self) private var videoModel
    var body: some View {
        @Bindable var videoModel=videoModel
        VStack {
            
            
            VideoNav()
            
            Spacer()
            
            VideoMainArea()
            
            
            Spacer()
            
            VideoTail()
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

#Preview {
    VideoView()
        .environment(VideoModel())
}
