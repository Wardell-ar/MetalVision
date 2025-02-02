//
//  PhotoModel.swift
//  WSR
//
//  Created by 吴泓霖 on 2024/11/28.
//

import Foundation
import UIKit
import Metal
import MetalFX
import MetalPerformanceShaders
import SwiftUI

@Observable
class PhotoModel{
    let device = MTLCreateSystemDefaultDevice()
    var originalImage: UIImage?
    var upscaledImage: UIImage?
    var showAlert = false // 控制提示框显示状态
    var fileURLToShare: URL?//用于分享的路径
    var imagePickerCoordinator: ImagePickerCoordinator? // 强引用 Coordinator
    var scaleFactor: Float = 1.5
    var selectedButton: String = "高清" // 用于记录当前被选中的按钮
    var showShareSheet = false
    var checkingPrevious=true
    
    var settingChange: Bool = false // 控制提示框的显示
    var changeMessage: String = "" // 提示框的内容
    
    func chooseImage() {
        
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        // 创建 ImagePickerCoordinator 实例并持有引用
        imagePickerCoordinator = ImagePickerCoordinator { image in
            if let selectedImage = image {
                self.clearPhoto()
                self.originalImage = selectedImage
            }
        }
        
        picker.delegate = imagePickerCoordinator // 这里设置为强引用的实例
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
            keyWindow.rootViewController?.present(picker, animated: true)
        }
    }

    func processImage(_ image: UIImage) {
        DispatchQueue.global().async {
            let device = MTLCreateSystemDefaultDevice()!
            if let result = upscaleImageWithMetalFX(uiImage: image, device: device, scaleFactor: self.scaleFactor) {
                DispatchQueue.main.async {
                    self.upscaledImage = result
                }
            }
           
        }
      
        
    }

    func saveImage(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        showAlert = true
    }
    func clearPhoto(){
        originalImage=nil
        upscaledImage=nil
        checkingPrevious=true
    }
}





class ImagePickerCoordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let completion: (UIImage?) -> Void

    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let image = info[.originalImage] as? UIImage
        completion(image)
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        completion(nil)
        picker.dismiss(animated: true)
    }
}
/// 将图片保存到临时目录，并返回文件 URL
func saveImageWithFileName(image: UIImage, fileName: String) -> URL {
    let tempDirectory = FileManager.default.temporaryDirectory
    let fileURL = tempDirectory.appendingPathComponent(fileName)
    
    if let data = image.pngData() {
        do {
            try data.write(to: fileURL)
            print("Image saved to: \(fileURL)")
           
        } catch {
            print("Error saving image: \(error)")
        }
    }
    
    return fileURL
}

// ShareSheet: 使用 UIActivityViewController 实现分享功能
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any] // 要分享的内容
    var applicationActivities: [UIActivity]? = nil // 自定义活动项

    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
