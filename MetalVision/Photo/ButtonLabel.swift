//
//  PhotoButton.swift
//  MetalVision
//
//  Created by 吴泓霖 on 2024/11/30.
//

import SwiftUI

struct ButtonLabel: View {
    let ButtonName:String
    var body: some View {
        ZStack{
            Rectangle()
                .fill(Color.accentColor)
                .frame(maxWidth: 200,maxHeight: 55)
                .cornerRadius(12) // 可选：添加圆角
            Text(ButtonName)
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    ButtonLabel(ButtonName: "选择图片")
}
