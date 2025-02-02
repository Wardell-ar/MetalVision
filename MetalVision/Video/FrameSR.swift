//
//  FrameSR.swift
//  Video
//
//  Created by 吴泓霖 on 2024/12/2.
//
import SwiftUI
import UIKit
import AVFoundation
import AVKit
import CoreVideo
import Metal
import MetalFX

public func createSampleBuffer(reference: CMSampleBuffer, pixelBuffer: CVPixelBuffer) throws -> CMSampleBuffer {
    var referenceTimingInfo = CMSampleTimingInfo()
    let getTimingInfoResult = CMSampleBufferGetSampleTimingInfo(
        reference,
        at: 0,
        timingInfoOut: &referenceTimingInfo
    )
    
   
    
    var formatDescriptionRaw: CMVideoFormatDescription?
    let createFormatDescRes = CMVideoFormatDescriptionCreateForImageBuffer(
        allocator: kCFAllocatorDefault,
        imageBuffer: pixelBuffer,
        formatDescriptionOut: &formatDescriptionRaw
    )
    
    let formatDescription = formatDescriptionRaw!
    
    var sampleBufferRaw: CMSampleBuffer?
    let sampleBufferCreateRes = CMSampleBufferCreateReadyWithImageBuffer(
        allocator: kCFAllocatorDefault,
        imageBuffer: pixelBuffer,
        formatDescription: formatDescription,
        sampleTiming: &referenceTimingInfo,
        sampleBufferOut: &sampleBufferRaw
    )
    
    let sampleBuffer = sampleBufferRaw!
    
    return sampleBuffer
}
@available(iOS 16.0, *)
func upscalePixelBufferWithMetalFX(pixelBuffer: CVPixelBuffer, scaleFactor: Float) -> CVPixelBuffer? {
    let device = MTLCreateSystemDefaultDevice()!
    // Convert CVPixelBuffer to MTLTexture
    guard let inputTexture = pixelBufferToMetalTexture(pixelBuffer: pixelBuffer, device: device) else {
        return nil
    }

    let width = min(Int(Float(inputTexture.width) * scaleFactor), 3840)
    let height = min(Int(Float(inputTexture.height) * scaleFactor), (width * inputTexture.height / inputTexture.width))
    let format = inputTexture.pixelFormat

    // Create output texture
    let outputDescriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: format,
        width: width,
        height: height,
        mipmapped: false
    )
    outputDescriptor.storageMode = .private
    outputDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]

    guard let outputTexture = device.makeTexture(descriptor: outputDescriptor) else {
        return nil
    }

    // Configure MetalFX Spatial Scaler
    let spatialScalerDescriptor = MTLFXSpatialScalerDescriptor()
    spatialScalerDescriptor.inputHeight = inputTexture.height
    spatialScalerDescriptor.inputWidth = inputTexture.width
    spatialScalerDescriptor.colorTextureFormat = format
    spatialScalerDescriptor.colorProcessingMode = .perceptual
    spatialScalerDescriptor.outputHeight = outputTexture.height
    spatialScalerDescriptor.outputWidth = outputTexture.width
    spatialScalerDescriptor.outputTextureFormat = format

    guard let spatialScaler = spatialScalerDescriptor.makeSpatialScaler(device: device) else {
        return nil
    }

    spatialScaler.colorTexture = inputTexture
    spatialScaler.inputContentWidth = inputTexture.width
    spatialScaler.inputContentHeight = inputTexture.height
    spatialScaler.outputTexture = outputTexture

    // Encode commands
    guard let commandQueue = device.makeCommandQueue(),
          let commandBuffer = commandQueue.makeCommandBuffer() else {
        return nil
    }

    spatialScaler.encode(commandBuffer: commandBuffer)
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    // Convert output texture to CVPixelBuffer
    return metalTextureToPixelBuffer(texture: outputTexture, pixelBufferPool: createPixelBufferPool(width: width, height: height))
}
//@available(iOS 16.0, *)
//func temporalUpscaling(pixelBuffer: CVPixelBuffer, scaleFactor: Float) -> CVPixelBuffer? {
//    
//    
//}
func pixelBufferToMetalTexture(pixelBuffer: CVPixelBuffer, device: MTLDevice) -> MTLTexture? {
    let pixelBufferFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
    print("Pixel format: \(pixelBufferFormat)")
    //let textureFormat: MTLPixelFormat = (pixelBufferFormat == kCVPixelFormatType_32BGRA) ? .bgra8Unorm : .rgba8Unorm

    let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba8Unorm_srgb ,
        width: CVPixelBufferGetWidth(pixelBuffer),
        height: CVPixelBufferGetHeight(pixelBuffer),
        mipmapped: false
    )
    textureDescriptor.usage = [.shaderRead, .shaderWrite]

   
    var textureCache: CVMetalTextureCache? = nil
    CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
    
    var texture: CVMetalTexture?
    guard let cache = textureCache,
          CVMetalTextureCacheCreateTextureFromImage(nil, cache, pixelBuffer, nil, textureDescriptor.pixelFormat, textureDescriptor.width, textureDescriptor.height, 0, &texture) == kCVReturnSuccess,
          let metalTexture = CVMetalTextureGetTexture(texture!) else {
        return nil
    }

    return metalTexture
}

func metalTextureToPixelBuffer(texture: MTLTexture, pixelBufferPool: CVPixelBufferPool?) -> CVPixelBuffer? {
    guard let pixelBufferPool = pixelBufferPool else { return nil }
    var pixelBuffer: CVPixelBuffer?
    CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &pixelBuffer)
    guard let buffer = pixelBuffer else { return nil }

    // 创建 MTLBuffer
    let bytesPerRow = texture.width * 4 // 假设是 BGRA 格式
    let bufferLength = bytesPerRow * texture.height
    guard let device = texture.device.makeBuffer(length: bufferLength, options: .storageModeShared) else {
        print("Failed to create MTLBuffer")
        return nil
    }

    // 使用 BlitCommandEncoder 拷贝数据
    guard let commandQueue = texture.device.makeCommandQueue(),
          let commandBuffer = commandQueue.makeCommandBuffer(),
          let blitEncoder = commandBuffer.makeBlitCommandEncoder() else {
        return nil
    }

    let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
    blitEncoder.copy(from: texture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: region.origin, sourceSize: region.size, to: device, destinationOffset: 0, destinationBytesPerRow: bytesPerRow, destinationBytesPerImage: bufferLength)
    blitEncoder.endEncoding()

    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    // 将 MTLBuffer 数据拷贝到 CVPixelBuffer
    CVPixelBufferLockBaseAddress(buffer, .readOnly)
    let pixelBufferAddress = CVPixelBufferGetBaseAddress(buffer)
    memcpy(pixelBufferAddress, device.contents(), bufferLength)
    CVPixelBufferUnlockBaseAddress(buffer, .readOnly)

    return buffer
}

func createPixelBufferPool(width: Int, height: Int) -> CVPixelBufferPool? {
    let poolAttributes: [String: Any] = [
        kCVPixelBufferPoolMinimumBufferCountKey as String: 2
    ]
    let bufferAttributes: [String: Any] = [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        kCVPixelBufferWidthKey as String: width,
        kCVPixelBufferHeightKey as String: height,
        kCVPixelBufferMetalCompatibilityKey as String: true
    ]

    var pixelBufferPool: CVPixelBufferPool?
    CVPixelBufferPoolCreate(nil, poolAttributes as CFDictionary, bufferAttributes as CFDictionary, &pixelBufferPool)
    return pixelBufferPool
}
