//
//  PhotoModel.swift
//  WSR
//
//  Created by 吴泓霖 on 2024/11/28.
//

import Foundation
import UIKit
import PhotosUI
import SwiftUI
import AVFoundation
import AVKit

@Observable
class VideoModel {
    var showAlert = false // 控制提示框显示状态
    var scaleFactor: Float = 1.5
    var showShareSheet = false
    var checkingPrevious=true
    var unsupportedFormat = false
    
    var inputPlayer: AVPlayer? = nil
    var outputPlayer: AVPlayer? = nil
    
    var videoPickerCoordinator: VideoPickerCoordinator? // 存储为属性
    var settingChange: Bool = false // 控制提示框的显示
    var changeMessage: String = "" // 提示框的内容
    
    var inputUrl:URL?
    var outputUrl: URL? /*= FileManager.default.temporaryDirectory.appendingPathComponent("output.mov")*/
    var _assetReader: AVAssetReader?
    var _assetWriter: AVAssetWriter?
    var _interruptFlag = false
    var _isGeneratingAsset = false
    var _processingQueue = DispatchQueue(
        label: "处理队列",
        qos: .default
    )
    var _videoTrackQueue = DispatchQueue(
        label: "视频队列",
        qos: .default
    )
    var _audioTrackQueue = DispatchQueue(
        label: "音频队列",
        qos: .default
    )
    var _audioTrackDidFinish: Bool = false
    var _videoTrackDidFinish: Bool = false
    var _previousFrameTimestamp: Date?
    var currentFramesPerSecond: Double = 0
    var startTime: Date?
    var generatedPreview: CGImage?
    var currentState: State = .queued
    var error: Error?
    var currentProgress: Double = 0
    
    func clearVideo(){
        inputPlayer=nil
        outputPlayer=nil
        checkingPrevious=true
        currentState = .queued
        currentProgress=0
        
        _assetReader = nil
        _assetWriter = nil
        _interruptFlag = false
        _isGeneratingAsset = false
        _processingQueue = DispatchQueue(
            label: "处理队列",
            qos: .default
        )
       _videoTrackQueue = DispatchQueue(
            label: "视频队列",
            qos: .default
        )
        _audioTrackQueue = DispatchQueue(
            label: "音频队列",
            qos: .default
        )
        _audioTrackDidFinish = false
        _videoTrackDidFinish = false
        _previousFrameTimestamp = nil
        currentFramesPerSecond = 0
        startTime = nil
        error = nil
 
//        if FileManager.default.fileExists(atPath: outputUrl.path!) {
//            print("[SR] Removing existing file at output location...")
//            try? FileManager.default.removeItem(at: outputUrl!)
//        }
    }
    
    func chooseVideo() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.movie"]
        picker.videoQuality = .typeHigh
        
        // 创建 VideoPickerCoordinator 实例并持有引用
        videoPickerCoordinator = VideoPickerCoordinator { videoUrl in
            // 检查扩展名
            let fileExtension = videoUrl!.pathExtension.lowercased()
            if fileExtension == "mov" || fileExtension == "mp4"{
                if let selectedUrl = videoUrl{
                    if fileExtension == "mov"{
                        self.outputUrl = FileManager.default.temporaryDirectory.appendingPathComponent("output.mov")
                    }else{
                        self.outputUrl = FileManager.default.temporaryDirectory.appendingPathComponent("output.mp4")
                    }
                    self.clearVideo()
                    //print(selectedUrl)
                    self.inputUrl=selectedUrl
                    self.inputPlayer=AVPlayer(url: selectedUrl)
                }
            }else {
                self.unsupportedFormat=true
            }
        }
        picker.delegate = videoPickerCoordinator // 这里设置为强引用的实例
        
        // 显示选择器
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
            keyWindow.rootViewController?.present(picker, animated: true)
        }
    }
 
    func processVideo(inputUrl: URL?) {
        currentState = .processing
        synchronizeVideoAndAudio(inputUrl: inputUrl)
        
        // Observe the state to update player for the output video
        DispatchQueue.global(qos: .background).async {
            while self.currentState != .finished {
                Thread.sleep(forTimeInterval: 0.5)
            }
            DispatchQueue.main.async {
                if self.currentState == .finished {
                    self.outputPlayer = AVPlayer(url: self.outputUrl!)
                }
            }
        }
    }
    func saveVideo(){
        if(checkingPrevious){
            UISaveVideoAtPathToSavedPhotosAlbum(inputUrl!.path, nil, nil, nil)
        }else{
            UISaveVideoAtPathToSavedPhotosAlbum(outputUrl!.path, nil, nil, nil)
        }
        showAlert = true
    }
    func _updateFps() {
        let now = Date()
        
        if let previous = _previousFrameTimestamp {
            let elapsed = now.timeIntervalSince(previous)
            self.currentFramesPerSecond = 1.0 / elapsed
        }
        
        _previousFrameTimestamp = now
    }
    /// 同步视频和音频
    func synchronizeVideoAndAudio(inputUrl: URL?) {
        
        let asset = AVURLAsset(url: (inputUrl)!)
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first,
              let audioTrack = asset.tracks(withMediaType: .audio).first else {
            print("No video or audio track found.")
            return
        }
      
        let sampleVideoSize = videoTrack.naturalSize
        let outputVideoSize = CGSize(
            width: sampleVideoSize.width * CGFloat(scaleFactor),
            height: sampleVideoSize.height * CGFloat(scaleFactor)
        )
        print("width:\(sampleVideoSize.width)")
        let sampleVideoDuration = CMTimeGetSeconds(asset.duration)    //        let formatDescription = audioTrack.formatDescriptions.first
        //        let streamDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription as! CMAudioFormatDescription)?.pointee
        //        print(formatDescription)
        do {
            let assetReader = try AVAssetReader(asset: asset)
            self._assetReader = assetReader
            // 配置视频和音频输出
            let videoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: [
                String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA
            ])
            let audioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                //                AVSampleRateKey: streamDescription?.mSampleRate,
                //                AVNumberOfChannelsKey: 2
            ])
            videoOutput.alwaysCopiesSampleData=false
            if assetReader.canAdd(videoOutput) { assetReader.add(videoOutput) }
            if assetReader.canAdd(audioOutput) { assetReader.add(audioOutput) }
            
            //assetReader.startReading()
            // Remove existing file
            if FileManager.default.fileExists(atPath: outputUrl!.path) {
                print("[SR] Removing existing file at output location...")
                try? FileManager.default.removeItem(at: outputUrl!)
            }
            // Setup writer
            let fileExtension = inputUrl!.pathExtension.lowercased()
            if fileExtension == "mov" {
                self._assetWriter = try AVAssetWriter(outputURL: outputUrl!, fileType: .mov)
            }else{
                self._assetWriter = try AVAssetWriter(outputURL: outputUrl!, fileType: .mp4)
            }
            
            guard let assetWriter = self._assetWriter else{
                return
            }
//            let codecType: AVVideoCodecType
//
//            if #available(iOS 11.0, *), AVAssetWriterInput.classForCoder()(.hevc) {
//                // 优先选择 HEVC 编码（iOS 11+ 支持）
//                codecType = .hevc
//            } else {
//                // 回退到 H.264
//                codecType = .h264
//            }
            let srFrameOutput = AVAssetWriterInput(
                mediaType: .video,
                outputSettings: [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: NSNumber(value: Int(outputVideoSize.width)),
                    AVVideoHeightKey: NSNumber(value: Int(outputVideoSize.height))
                ]
            )
            //srFrameOutput.expectsMediaDataInRealTime = false
            let srAudioOutput = AVAssetWriterInput(
                mediaType: .audio,
                outputSettings: nil
            )
            
            assetWriter.add(srFrameOutput)
            assetWriter.add(srAudioOutput)
            
            // Start reading and writing
            assetReader.startReading()
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: .zero)
            print("[ConvertingAsset] Current reader status is \(assetReader.status.rawValue), writer status is \(assetWriter.status.rawValue)")
            
            
            
            // Process frames
            srFrameOutput.requestMediaDataWhenReady(on: _videoTrackQueue) { [weak self] in
                guard let self = self else { return }
                let cleanup = {
                    self._videoTrackDidFinish = true
                    srFrameOutput.markAsFinished()
                    self._onTrackFinish()
                }
                
                do {
                    while srFrameOutput.isReadyForMoreMediaData {
                        try autoreleasepool {
                            if self._interruptFlag {
                                DispatchQueue.main.sync {
                                    self.currentState = .queued
                                    cleanup()
                                }
                                return
                            }
                            
                            if assetReader.status != .reading {
                                if let error = assetReader.error {
                                    DispatchQueue.main.sync {
                                        print("[SR] Reader error: \(error)")
                                        self._interruptFlag = true
                                        self.error = error
                                        self.currentState = .failed
                                    }
                                }
                                cleanup()
                                return
                            }
                            
                            if assetWriter.status == .failed {
                                DispatchQueue.main.sync {
                                    print("[SR] Reader error: \(assetWriter.error!)")
                                    self._interruptFlag = true
                                    self.error = assetWriter.error
                                    self.currentState = .failed
                                    cleanup()
                                }
                                return
                            }
                            
                            guard let frameBuf = videoOutput.copyNextSampleBuffer() else {
                                print("[SR] Reached the end of video frames.")
                                cleanup()
                                return
                            }
                            let frameImgBuf = CMSampleBufferGetImageBuffer(frameBuf)!
                            
                            let frameTimestamp = CMSampleBufferGetPresentationTimeStamp(frameBuf)
                            let frameTime = CMTimeGetSeconds(frameTimestamp)
                            
                            DispatchQueue.main.async {
                                self._updateFps()
                                self.currentProgress = Double(frameTime / sampleVideoDuration)
                            }
                            
                            
                            //后续利用超分函数把frameImgBuf转化为srFrame
                            let srFrame=upscalePixelBufferWithMetalFX(pixelBuffer: frameImgBuf, scaleFactor: self.scaleFactor)
                            
                            let srFrameBuf = try createSampleBuffer(
                                reference: frameBuf,
                                pixelBuffer: srFrame!
                            )
                            
                            srFrameOutput.append(srFrameBuf)//后面改为srFrameBuf
                        }
                    }
                } catch {
                    DispatchQueue.main.sync {
                        print("[SR] Errored: \(error)")
                        self._interruptFlag = true
                        self.error = error
                        self.currentState = .failed
                        cleanup()
                    }
                }
            }
            
            srAudioOutput.requestMediaDataWhenReady(on: _audioTrackQueue) { [weak self] in
                guard let self = self else { return }
                let cleanup = {
                    self._audioTrackDidFinish = true
                    srAudioOutput.markAsFinished()
                    self._onTrackFinish()
                }
                
                while srAudioOutput.isReadyForMoreMediaData {
                    autoreleasepool {
                        if self._interruptFlag {
                            cleanup()
                            return
                        }
                        
                        if assetReader.status != .reading {
                            cleanup()
                            return
                        }
                        
                        guard let nextSample = audioOutput.copyNextSampleBuffer() else {
                            print("[SR] Reached the end of audio track.")
                            cleanup()
                            return
                        }
                        
                        srAudioOutput.append(nextSample)
                    }
                }
            }
            
        } catch {
            print("Error creating asset reader: \(error.localizedDescription)")
        }
    }
    func _onTrackFinish() {
        if _audioTrackDidFinish && _videoTrackDidFinish {
            if let writer = self._assetWriter {
                writer.finishWriting {
                    DispatchQueue.main.async {
                        print("[SR] Finished writing to file.")
                        self._assetReader = nil
                        self._assetWriter = nil
                        self.currentProgress = 1.0
                        
                        if self.currentState == .processing {
                            self.currentState = .finished
                        }
                    }
                }
            }
        }
    }
    
}
extension VideoModel {
    enum State: String {
        case queued = "Queued"
        case processing = "Processing"
        case finished = "Finished"
        case failed = "Failed"
    }
    
}

// VideoPickerCoordinator 类
class VideoPickerCoordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let completion: (URL?) -> Void

    init(completion: @escaping (URL?) -> Void) {
        self.completion = completion
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let videoUrl = info[.mediaURL] as? URL
        completion(videoUrl)
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        completion(nil)
        picker.dismiss(animated: true)
    }
}
