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
    private let sampleQueue = DispatchQueue.init(label: "ijf_sample_queue", qos: .default, attributes: [], autoreleaseFrequency: .never)
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    private var videoDevice: AVCaptureDevice?
    private var audioDevice: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    
    public private(set) var camera = VideoCollectorConfig.Camera.back
    
    public var config: VideoCollectorConfig! {
        didSet {
            try? updateConfigIfNeeded()
        }
    }
    
    public static func realCollector() -> VideoCollector {
        VideoCollector(config: VideoCollectorConfig())
    }
    
    init(config: VideoCollectorConfig) {
        self.config = config
        super.init()
        if session.canSetSessionPreset(config.videoQuality) {
            session.sessionPreset = config.videoQuality
        } else {
            session.sessionPreset = .high
        }

        switchCamera(to: .back)
        
        if let audioDevice = AVCaptureDevice.default(for: .audio) {
            self.audioDevice = audioDevice
            if let input = try? AVCaptureDeviceInput.init(device: audioDevice) {
                if session.canAddInput(input) {
                    session.addInput(input)
                }
            }
        }
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        videoOutput.alwaysDiscardsLateVideoFrames = false
        videoOutput.setSampleBufferDelegate(self, queue: sampleQueue)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: sampleQueue)
        if session.canAddOutput(audioOutput) {
            session.addOutput(audioOutput)
        }
    }
    
    deinit {
        print("-collector deinit-")
    }
}

extension VideoCollector {
    public func startCollect(preview: UIView?) {
        if session.isRunning {
            return
        }
        session.startRunning()
        if let onView = preview {
            onView.layer.backgroundColor = UIColor.black.cgColor
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
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
 
    
    /// 切换摄像头
    /// - Parameter camera: 前置和、后置
    public func switchCamera(to camera: VideoCollectorConfig.Camera) {
        if let device = getVideoDevice(camera: camera) {
            self.camera = camera
            self.videoDevice = device
            updateSession {
                if let videoInput = self.videoInput {
                    session.removeInput(videoInput)
                }
                if let input = try? AVCaptureDeviceInput.init(device: device) {
                    if session.canAddInput(input) {
                        session.addInput(input)
                        self.videoInput = input
                    }
                }
            }
        }
    }
}

extension VideoCollector {
    private func getVideoDevice(camera: VideoCollectorConfig.Camera) -> AVCaptureDevice? {
        var device: AVCaptureDevice?
        let videoDevices = AVCaptureDevice.devices(for: .video)
        for videoDevice in videoDevices {
            if camera == .back {
                if videoDevice.position == .back {
                    device = videoDevice
                    break
                }
            }
            else {
                if videoDevice.position == .front {
                    device = videoDevice
                    break
                }
            }
        }
        return device
    }
    
    private func updateDevice(lock configure: (() -> Void), device: AVCaptureDevice) throws {
        do {
            try device.lockForConfiguration()
            configure()
            device.unlockForConfiguration()
        } catch {
            throw CollectorError.updateDevice
        }
    }
    
    private func updateSession(lock configure: (() -> Void)) {
        session.beginConfiguration()
        configure()
        session.commitConfiguration()
    }
    
    private func updateConfigIfNeeded() throws {
        guard let videoDevice = videoDevice else {
            return
        }
        do {
            try updateDevice(lock: { [weak self] in
                guard let self = self  else {
                    return
                }
                videoDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: self.config.videoFPS)
                videoDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: self.config.videoFPS)
            }, device: videoDevice)
        } catch {
             throw CollectorError.updateDevice
        }
        
        updateSession {
            session.sessionPreset = config.videoQuality
        }
        
    }
}

extension VideoCollector {
    enum CollectorError: Error {
        case updateDevice
    }
}

extension VideoCollector: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    // 采集的原始数据
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
}
