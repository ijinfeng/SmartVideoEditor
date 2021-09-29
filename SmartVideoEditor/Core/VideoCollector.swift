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
    public private(set) var camera = Camera.back
    
    private let sampleQueue = DispatchQueue.init(label: "ijf_sample_queue", qos: .default, attributes: [], autoreleaseFrequency: .never)
    
    public weak var delegate: VideoCollectorDelegate?
    
    public lazy var filter = VideoFilter()
    
    private var videoPreviewLayer: VideoPreviewLayer?
    private var videoDevice: AVCaptureDevice?
    private var audioDevice: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private lazy var context: CIContext = {
        if #available(iOS 12.0, *) {
            return CIContext()
        } else {
            if let eaglContext = EAGLContext.init(api: EAGLRenderingAPI.openGLES2) {
                return CIContext.init(eaglContext: eaglContext)
            }
            return CIContext.init(options: nil)
        }
    }()
    
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

        switchCamera(to: config.camera)
        
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
    
    /// 开始采集
    /// - Parameter preview: 展示到哪里
    public func startCollect(preview: UIView?) {
        if session.isRunning {
            return
        }
        if let onView = preview {
            onView.layer.backgroundColor = UIColor.black.cgColor
//            videoPreviewLayer?.videoGravity = .resizeAspectFill
            videoPreviewLayer = VideoPreviewLayer()
            videoPreviewLayer?.frame = onView.bounds
            onView.layer.insertSublayer(videoPreviewLayer!, at: 0)
        } else {
            videoPreviewLayer?.removeFromSuperlayer()
            videoPreviewLayer = nil
        }
        session.startRunning()
    }
    
    /// 停止采集
    public func stopCollcet() {
        if session.isRunning {
            session.stopRunning()
        }
    }
 
    
    /// 切换摄像头
    /// - Parameter camera: 前置、后置
    public func switchCamera(to camera: Camera) {
        if videoDevice != nil {
            guard self.camera != camera else {
                return
            }
        }
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
    
    /// 设置画面镜像
    /// - Parameter mirror: 当设置为 auto 时，即前置摄像头镜像，后置摄像头不镜像
    public func setMirror(_ mirror: MirrorType) {
        config.mirrorType = mirror
    }
    
    /// 设置闪光灯
    /// - Parameter torch: 模式
    public func setTorch(_ torch: Torch) {
        guard config.toggleTorch != torch else {
            return
        }
        if let currentDevice = self.videoDevice {
            try? updateDevice(lock: {
                if currentDevice.hasFlash && currentDevice.isFlashAvailable {
                    var support: AVCaptureDevice.TorchMode = .auto
                    if torch == .auto {
                        support = .auto
                    } else if torch == .on {
                        support = .on
                    } else {
                        support = .off
                    }
                    if currentDevice.isTorchModeSupported(support) {
                        currentDevice.torchMode = support
                        config.toggleTorch = torch
                    }
                }
            }, device: currentDevice)
        }
    }
}

extension VideoCollector {
    private func getVideoDevice(camera: Camera) -> AVCaptureDevice? {
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
            throw VideoSessionError.Collector.updateDevice
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
             throw VideoSessionError.Collector.updateDevice
        }
        
        updateSession {
            session.sessionPreset = config.videoQuality
        }
        
        switchCamera(to: config.camera)
    }
    
    private func setVideoOrientation(connection: AVCaptureConnection, _ o: AVCaptureVideoOrientation = .portrait) {
        if connection.isVideoOrientationSupported && connection.videoOrientation != o {
            connection.videoOrientation = o
        }
    }
    
    private func setVideoMirror(connection: AVCaptureConnection, _ mirror: MirrorType = .auto) {
        if connection.isVideoMirroringSupported {
            if mirror == .auto {
                if camera == .front {
                    connection.isVideoMirrored = true
                } else {
                    connection.isVideoMirrored = false
                }
            } else if mirror == .none {
                connection.isVideoMirrored = false
            } else {
                connection.isVideoMirrored = true
            }
        }
    }
}


extension VideoCollector: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    // 采集的原始数据
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let previewLayer = videoPreviewLayer {
            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                var oimage = CIImage.init(cvPixelBuffer: imageBuffer)
                oimage = filter.apply(to: oimage)
                let outputImage = context.createCGImage(oimage, from: oimage.extent)
                DispatchQueue.main.async {
                    previewLayer.contents = outputImage
                }
            }
        }
        
        if let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer) {
            let type = CMFormatDescriptionGetMediaType(formatDesc)
            if type == kCMMediaType_Video {
                setVideoOrientation(connection: connection, config.videoOrientation)
                setVideoMirror(connection: connection, config.mirrorType)
            }
        }
        
        delegate?.captureOutput(output, didOutput: sampleBuffer, from: connection)
    }
}
