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
    
    private let sampleQueue = DispatchQueue.init(label: "ijf_sample_queue", qos: .default, attributes: [])
    private let collectQueue = DispatchQueue.init(label: "ijf_collect_queue")
    
    public weak var delegate: VideoCollectorDelegate?
    
    public lazy var filter = VideoFilter()
    
    private var focusImage: UIImage?
    private var videoPreview: VideoPreviewView?
    private var videoPreviewLayer: VideoPreviewLayer?
    private var videoDevice: AVCaptureDevice?
    private var audioDevice: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    internal lazy var context: CIContext = {
        if #available(iOS 12.0, *) {
            return CIContext()
        } else {
            if let eaglContext = EAGLContext.init(api: EAGLRenderingAPI.openGLES2) {
                return CIContext.init(eaglContext: eaglContext)
            }
            return CIContext.init(options: nil)
        }
    }()
    
    private var mirror: MirrorType = .auto
    
    public var config: VideoCollectorConfig! {
        didSet {
            try? updateConfigIfNeeded()
        }
    }
    
    public static func realCollector() -> VideoCollector {
        VideoCollector(config: VideoCollectorConfig())
    }
    
    init(config: VideoCollectorConfig) {
        super.init()
        self.config = config
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
        setVideoDataOutput()
        setAudioDataOutput()
    }
    
    deinit {
        print("-collector deinit-")
    }
}

// MARK: Public API
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
            videoPreview = VideoPreviewView()
            videoPreview?.delegate = self
            videoPreview?.frame = onView.bounds
            videoPreview?.setCustomFocusImage(focusImage)
            videoPreview?.enablePinch = config.enableZoom
            onView.insertSubview(videoPreview!, at: 0)
            videoPreviewLayer = videoPreview?.layer as? VideoPreviewLayer
        } else {
            videoPreview?.removeFromSuperview()
            videoPreview = nil
            videoPreviewLayer?.removeFromSuperlayer()
            videoPreviewLayer = nil
        }
        collectQueue.async {
            self.session.startRunning()
        }
    }
    
    /// 停止采集
    public func stopCollcet() {
        if session.isRunning {
            collectQueue.async {
                self.session.stopRunning()
            }
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
        guard canSwitchCamera() else {
            return
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
    
    /// 设置聚焦曝光的图片
    /// - Parameter image: 当设置为 `nil` 时，将使用默认的样式
    public func setFocusImage(_ image: UIImage?) {
        focusImage = image
        videoPreview?.setCustomFocusImage(image)
    }
    
    /// 设置缩放比例
    /// - Parameter scale: 1.0 ~ 3.0
    /// - Parameter velocity: 缩放速度
    public func setZoom(_ scale: CGFloat, _ velocity: CGFloat = 100.0) {
        var _scale = scale
        if _scale < 1.0 {
            _scale = 1.0
        }
        if let currentDevice = self.videoDevice {
            let maxScale = currentDevice.activeFormat.videoMaxZoomFactor
            _scale = min(_scale, maxScale)
            try? updateDevice(lock: {
                currentDevice.ramp(toVideoZoomFactor: _scale, withRate: Float(velocity))
            }, device: currentDevice)
        }
    }
}

// MARK: 坐标转换
/// 你传递一个CGPoint，其中{0,0}表示图像区域的左上角，而{1,1}表示右下方在横向模式下，右侧的主屏幕按钮 - 即使设备处于纵向模式，也适用
/// 它是指比例。例如，如果您想要着眼于{0.5,0.2}点的边界大小{20,100}，请点击{10,20}。
/// https://blog.csdn.net/qq_30513483/article/details/51198464
/// 需要考虑视频重力、镜像、矩阵变换和屏幕方向
/// 屏幕坐标左上角(0,0)。摄像头坐标：home键在右边，此时左上角为(0,0)，右下角(1,1)
extension VideoCollector {

    /// 将`UIView`上的点转换成摄像头点的位置
    /// - Parameter point: uiview上的点
    /// - Returns: 摄像头上的点
    public func captureDevicePointConverted(fromView point: CGPoint) -> CGPoint {
        if let videoPreview = videoPreview {
            var _window: UIWindow?
            if #available(iOS 13.0, *) {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    _window = scene.windows.first
                }
            } else {
                _window = UIApplication.shared.windows.first
            }
            if let window = _window {
                let convert = videoPreview.convert(videoPreview.frame, to: window)
                let x = point.y / convert.size.height
                let y = 1 - point.x / convert.size.width
                return CGPoint(x: x, y: y)
            } else {
                return .zero
            }
        } else {
            return .zero
        }
    }
}

// MARK: Private API
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
    
    private func canSwitchCamera() -> Bool {
        AVCaptureDevice.devices(for: .video).count > 1
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
                let setFrameRate = min(self.config.videoFPS, videoDevice.maxSupportFrameRate())
                videoDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(setFrameRate))
                videoDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(setFrameRate))
                if videoDevice.isFocusModeSupported(.autoFocus) {
                    videoDevice.focusMode = .autoFocus
                }
                if videoDevice.isExposureModeSupported(.autoExpose) {
                    videoDevice.exposureMode = .autoExpose
                }
                if videoDevice.isSmoothAutoFocusSupported {
                    videoDevice.isSmoothAutoFocusEnabled = true
                }
            }, device: videoDevice)
        } catch {
             throw VideoSessionError.Collector.updateDevice
        }
        
        updateSession {
            session.sessionPreset = config.videoQuality
        }
        
        switchCamera(to: config.camera)
        
        videoPreview?.enablePinch = config.enableZoom
    }
    
    private func setVideoOrientation(connection: AVCaptureConnection, _ o: AVCaptureVideoOrientation = .portrait) {
        if connection.isVideoOrientationSupported && connection.videoOrientation != o {
            connection.videoOrientation = o
        }
    }
    
    private func setVideoMirror(connection: AVCaptureConnection, _ mirror: MirrorType = .auto) {
        if connection.isVideoMirroringSupported && self.mirror != mirror {
            print("self.mirrot=\(self.mirror), mirror=\(mirror)")
            self.mirror = mirror
            if mirror == .auto {
                if camera == .front {
                    connection.isVideoMirrored = true
                } else {
                    connection.isVideoMirrored = false
                }
            } else if mirror == .no {
                connection.isVideoMirrored = false
            } else {
                connection.isVideoMirrored = true
            }
        }
    }
    
    private func setVideoDataOutput() {
        let videoOutput = AVCaptureVideoDataOutput()
        self.videoOutput = videoOutput
        videoOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        videoOutput.alwaysDiscardsLateVideoFrames = false
        videoOutput.setSampleBufferDelegate(self, queue: sampleQueue)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
    }
    
    private func setAudioDataOutput() {
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: sampleQueue)
        if session.canAddOutput(audioOutput) {
            session.addOutput(audioOutput)
        }
    }
    
    private func setTouchFocus(at point: CGPoint) {
        guard config.touchFocus else {
            return
        }
        if let currentDevice = self.videoDevice {
            try? updateDevice(lock: {
                if currentDevice.isFocusPointOfInterestSupported {
                    currentDevice.focusPointOfInterest = point
                }
                if currentDevice.isExposurePointOfInterestSupported {
                    currentDevice.exposurePointOfInterest = point
                }
                if currentDevice.isFocusModeSupported(.autoFocus) {
                    currentDevice.focusMode = .autoFocus
                }
                if currentDevice.isExposureModeSupported(.autoExpose) {
                    currentDevice.exposureMode = .autoExpose
                }
            }, device: currentDevice)
        }
    }
}

// MARK: VideoPreviewViewDelegate
extension VideoCollector: VideoPreviewViewDelegate {
    func didTouch(at point: CGPoint) {
        let devicePoint = captureDevicePointConverted(fromView: point)
        setTouchFocus(at: devicePoint)
    }
    
    func didPinching(scale: CGFloat, velocity: CGFloat) {
        setZoom(scale)
    }
}

// MARK: AVCaptureDataOutputSampleBufferDelegate
extension VideoCollector: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    // 采集的原始数据
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer) {
            let type = CMFormatDescriptionGetMediaType(formatDesc)
            if type == kCMMediaType_Video {
                if config.orientationType == .auto {
                    setVideoOrientation(connection: connection, UIDevice.currentOrientation())
                } else {
                    setVideoOrientation(connection: connection, config.videoOrientation)
                }
                setVideoMirror(connection: connection, config.mirrorType)
            }
        }
        if let previewLayer = videoPreviewLayer {
            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                var oimage = CIImage.init(cvPixelBuffer: imageBuffer)
                oimage = filter.apply(to: oimage)
                let outputImage = context.createCGImage(oimage, from: oimage.extent)
                delegate?.captureOutput(outputImage, didOutput: sampleBuffer)
                DispatchQueue.main.async {
                    previewLayer.contents = outputImage
                }
            }
        }
        delegate?.captureOutput(output, didOutput: sampleBuffer, from: connection)
    }
}
