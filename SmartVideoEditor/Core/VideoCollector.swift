//
//  VideoCollector.swift
//  SmartVideoEditor
//
//  Created by JinFeng on 2021/9/20.
//

import UIKit
import AVFoundation

/// 视频采集器，捕捉从摄像头，麦克风采集的数据流。或者从本地相册读取的视频
public class VideoCollector: NSObject {
    
    public let session = AVCaptureSession()
    private let videoQueue = DispatchQueue.init(label: "ijf_video")
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    public let config: VideoCollectorConfig!
    
    static func realCollector() -> VideoCollector {
        VideoCollector(config: VideoCollectorConfig())
    }
    
    init(config: VideoCollectorConfig) {
        self.config = config
        super.init()
        if session.canSetSessionPreset(.hd1280x720) {
            session.sessionPreset = .hd1280x720
        } else {
            session.sessionPreset = .high
        }
        if let device = AVCaptureDevice.default(for: .video) {
            if let input = try? AVCaptureDeviceInput.init(device: device) {
                session.addInput(input)
            }
        }
        let output = AVCaptureVideoDataOutput()
        session.addOutput(output)
        output.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        output.alwaysDiscardsLateVideoFrames = false
        output.setSampleBufferDelegate(self, queue: videoQueue)
    }
    
    public func startCollect(preview: UIView?) {
        if session.isRunning {
            return
        }
        session.startRunning()
        if let onView = preview {
            onView.layer.backgroundColor = UIColor.black.cgColor
            videoPreviewLayer = AVCaptureVideoPreviewLayer()
            videoPreviewLayer?.frame = onView.bounds
            videoPreviewLayer?.videoGravity = .resizeAspectFill
            onView.layer.insertSublayer(videoPreviewLayer!, at: 0)
        } else {
            videoPreviewLayer?.removeFromSuperlayer()
            videoPreviewLayer = nil
        }
    }
    
    public func stopCollcet() {
        if session.isRunning {
            session.stopRunning()
        }
    }
 
    
    public func switchCamera(to camera: VideoCollectorConfig.Camera) {
        
    }
}

extension VideoCollector: AVCaptureVideoDataOutputSampleBufferDelegate {
    // 采集的原始数据
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
}
