//
//  IntroPages.swift
//  MetalVision
//
//  Created by 吴泓霖 on 2024/11/29.
//

import Foundation
import SwiftUI

struct IntroPage: Identifiable{
    let id: UUID
    let title:String
    let description:String
    let imageName:String
}

var IntroPages:[IntroPage]=[
    IntroPage(id: UUID(), title: "原生集成", description: "MetalFX框架与Metal原生集成，轻松将低分辨率的图像或视频升级到更高的输出分辨率",imageName: "Launch"),
    IntroPage(id: UUID(), title: "高效低耗", description: "充分利用NPU的高效计算与低功耗特性，以不到0.5w的功耗快速完成图像超分辨率增强",imageName: "M4"),
    IntroPage(id: UUID(), title: "安全舒心", description: "充分利用本地硬件，一键提升画面的细节与清晰度，响应迅速同时全程断网保障隐私安全",imageName: "Privacy")
]
