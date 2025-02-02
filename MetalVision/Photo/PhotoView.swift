//
//  PhotoView.swift
//  MetalVision
//
//  Created by 吴泓霖 on 2024/11/29.
//

import SwiftUI
import UIKit
import Social


struct PhotoView: View {
    @Environment(PhotoModel.self) private var photoModel

    var body: some View {
        @Bindable var photoModel = photoModel
        VStack {
            
            
            PhotoNav()
            
            Spacer()
            
            PhotoMainArea()
            
            
            Spacer()
            
            PhotoTail()
        }
        .background(Color(UIColor.systemGroupedBackground))
        
        
        
        
       
    }
}

    

#Preview {
    PhotoView()
        .environment(PhotoModel())
}
