//
//  ImageProcessor.swift
//  WSR
//
//  Created by 吴泓霖 on 2024/11/27.
//

import UIKit
import Metal
import MetalFX
import MetalPerformanceShaders

@available(iOS 16.0, *)
func upscaleImageWithMetalFX(uiImage: UIImage, device: MTLDevice, scaleFactor: Float) -> UIImage? {
    guard let inputTexture = uiImageToMetalTexture(uiImage: uiImage, device: device) else {
        return nil
    }

    let width = min(Int(Float(inputTexture.width) * scaleFactor),3840)
    let height = min(Int(Float(inputTexture.height) * scaleFactor),(width*inputTexture.height/inputTexture.width))
    let format = inputTexture.pixelFormat
    
    let outputDescriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: format,
        width: width,
        height: height,
        mipmapped: false)//true?
    outputDescriptor.storageMode = .private // 设置为 private
    outputDescriptor.usage = [ .renderTarget, .shaderRead, .shaderWrite ] // 添加 .renderTarget
    
    guard let outputTexture = device.makeTexture(descriptor: outputDescriptor) else {
        return nil
    }

    let commandQueue = device.makeCommandQueue()
    let commandBuffer = commandQueue?.makeCommandBuffer()

    let spatialScalerDescriptor = MTLFXSpatialScalerDescriptor()

    let supported = MTLFXSpatialScalerDescriptor.supportsDevice(device)
    print("Supported?: \(supported)")

    // Input
    spatialScalerDescriptor.inputHeight = inputTexture.height
    spatialScalerDescriptor.inputWidth = inputTexture.width
    spatialScalerDescriptor.colorTextureFormat = format
    spatialScalerDescriptor.colorProcessingMode = .perceptual

    // Output
    spatialScalerDescriptor.outputHeight = outputTexture.height
    spatialScalerDescriptor.outputWidth = outputTexture.width
    spatialScalerDescriptor.outputTextureFormat = format

    let spatialScaler = spatialScalerDescriptor.makeSpatialScaler(device: device)
    print("spatialScaler: \(String(describing: spatialScaler))")

    spatialScaler?.colorTexture = inputTexture
    spatialScaler?.inputContentWidth = inputTexture.width
    spatialScaler?.inputContentHeight = inputTexture.height
    spatialScaler?.outputTexture = outputTexture

    spatialScaler?.encode(commandBuffer: commandBuffer!)

    commandBuffer?.commit()

    commandBuffer?.waitUntilCompleted()

    // Convert MTLTexture to UIImage
    guard let ciImage = CIImage(mtlTexture: outputTexture, options: nil)?.oriented(.downMirrored) else {
        return nil
    }

    let context = CIContext(mtlDevice: device)
    guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
        return nil
    }

    let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: uiImage.imageOrientation)
    return uiImage
}

func uiImageToMetalTexture(uiImage: UIImage, device: MTLDevice) -> MTLTexture? {
    // Convert UIImage to CGImage
    guard let cgImage = uiImage.cgImage else {
        return nil
    }

    // Create MTLTextureDescriptor
    let width = cgImage.width
    print("width: \(width)")
    let height = cgImage.height
    print("height: \(height)")
    let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba8Unorm_srgb,
        width: width,
        height: height,
        mipmapped: false)
    textureDescriptor.usage = [.shaderRead, .shaderWrite]
    // Create MTLTexture
    guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
        return nil
    }

    // Copy image data to MTLTexture
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width

    var imageData = [UInt8](repeating: 0, count: bytesPerRow * height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

        guard let context = CGContext(
            data: &imageData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            print("Failed to create CGContext")
            return nil
        }

        // 绘制 UIImage 到 CGContext，提取像素数据
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(cgImage, in: rect)

        // 将像素数据拷贝到 Metal 纹理
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.replace(region: region, mipmapLevel: 0, withBytes: imageData, bytesPerRow: bytesPerRow)

        return texture
}


