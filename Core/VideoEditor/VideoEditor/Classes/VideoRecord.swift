//
//  VideoRecorder.swift
//  VideoRecorder
//
//  Created by jinfeng on 2021/9/22.
//

import UIKit
import AVFoundation

/// 视频录制
public class VideoRecord: NSObject {
    
    public let config: VideoRecordConfig!
    
    /// 视频信息采集
    public let collector = VideoCollector.realCollector()
    
    /// 视频录制的存放地址
    private var recordSavePath: String?
    
    /// 视频片段管理
    public let partsManager = VideoPartsManager()

    private let writeVideoInput: AVAssetWriterInput!
    private let writeAudioInput: AVAssetWriterInput!
    
    /// 录制是否暂停
    public private(set) var isPause: Bool = false
    /// 是否正在录制
    public private(set) var isRecording: Bool = false
    /// 是否静音
    public private(set) var isMute: Bool = false
    
    public weak var delegate: VideoRecordDelegate?
    
    /// 记录最后一帧的结束时间，也就是下一帧的开始时间
    private var lastInputVideoEndTime: CMTime = .zero
    private var lastInputAudioEndTime: CMTime = .zero
    /// 开始录制的时间
    private var startRecordTime: CMTime = .zero
    /// 暂停的时长
    private var pauseOffsetTime: CMTime = .zero
    /// 中间是否有暂停过
    private var interrupt = false
    /// 录制总时长
    private var duration: CMTime = .zero
    
    /// 拍照的回调
    private var photoCallback: ((UIImage) -> Void)?
    
    public init(config: VideoRecordConfig = VideoRecordConfig()) {
        self.config = config
        
        var bitRate = config.pixelsSize().height * config.pixelsSize().width * 32 /*没像素比特*/
        if let customBitRate = config.customBitRate {
            bitRate = customBitRate
        }
        var codecType: Any?
        if #available(iOS 11.0, *) {
            codecType = AVVideoCodecType.h264
        } else {
            codecType = AVVideoCodecH264
        }
        let compression: [String: Any] = [
            // 编码时的平均比特率
            AVVideoAverageBitRateKey: bitRate,
            // 期望帧率
            AVVideoExpectedSourceFrameRateKey: config.videoFPS,
            // 两个关键帧之间最大的间隔帧数
            AVVideoMaxKeyFrameIntervalKey: 10,
            // 画质级别：https://www.cnblogs.com/DMDD/p/4996765.html
            AVVideoProfileLevelKey: AVVideoProfileLevelH264MainAutoLevel
        ]
        let videoSetting: [String: Any] = [
            // 编码格式
            AVVideoCodecKey: codecType!,
            // 分辨率
            AVVideoWidthKey: config.pixelsSize().width,
            AVVideoHeightKey: config.pixelsSize().height,
            AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
            // 编码配置
            AVVideoCompressionPropertiesKey: compression
        ]
        writeVideoInput = AVAssetWriterInput.init(mediaType: .video, outputSettings: videoSetting, sourceFormatHint: nil)
        writeVideoInput.expectsMediaDataInRealTime = true
        
        let audioSetting: [String: Any] = [
            // 编码格式
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            // 声道数，2为双通道，表示立体声。除非使用外部硬件录制，否则通常使用单通道即可
            AVNumberOfChannelsKey: 1,
            // 采样率
            AVSampleRateKey: config.audioSampleRate.rawValue,
            // 码率
            AVEncoderBitRateKey: 128000
        ]
        writeAudioInput = AVAssetWriterInput.init(mediaType: .audio, outputSettings: audioSetting, sourceFormatHint: nil)
        writeAudioInput.expectsMediaDataInRealTime = true
        
        super.init()
        collector.delegate = self
    }
    
    deinit {
        print("-record deinit-")
        stopRecord()
    }
}


extension VideoRecord {
    
    /// 开始采集音视频，并显示预览效果
    /// - Parameter preview: 预览效果展示的`view`
    public func startCollect(preview : UIView?) {
        collector.startCollect(preview: preview)
    }
    
    /// 停止音视频采集
    public func stopCollect() {
        collector.stopCollcet()
    }

    /// 开始录制
    /// - Parameter videoPath: 录制输出路径
    /// - Returns: 录制状态
    public func startRecord(in outputVideoPath: String? = nil) throws {
        guard !isRecording else {
            print("the recording has begun")
            return
        }
        if let path = outputVideoPath {
            recordSavePath = path
        } else {
            recordSavePath = VideoRecordConfig.defaultRecordOutputDirPath + "record.mp4"
            FileHelper.createDir(at: VideoRecordConfig.defaultRecordOutputDirPath)
        }
        print("record path is: \(recordSavePath ?? "")")
        if recordSavePath?.count == 0 {
            throw VideoSessionError.Record.outputRecordPathError
        }
        
        isRecording = true
        isPause = false
        interrupt = false
        lastInputVideoEndTime = .zero
        lastInputAudioEndTime = .zero
        startRecordTime = .zero
        duration = .zero
        // 每次开始录制前删除旧的录制片段
        partsManager.resetPart()
        
        try addOnePart()
    }
    
    /// 继续录制
    public func resume() throws {
        guard isRecording else {
            print("record is not start")
            return
        }
        guard isPause else {
            print("record is not pause")
            return
        }
        print("resume record")
        isPause = false
        
        try addOnePart()
    }
    
    /// 暂停录制。每次暂停，都会生成一个视频片段
    public func pauseRecord() {
        guard isRecording else {
            print("record is not start")
            return
        }
        guard !isPause else {
            print("record is aleady pause")
            return
        }
        print("pause record")
        isPause = true
        interrupt = true
        
        if let writer = partsManager.currentPart?.writer {
            stopOnePart(writer: writer)
        }
    }
    
    /// 停止录制
    public func stopRecord() {
        guard isPause || isRecording else {
            print("aleady stop record")
            return
        }
        print("stop record")
        isRecording = false
        if let writer = partsManager.currentPart?.writer {
            DispatchQueue.main.async {
                self.delegate?.didStopRecord()
            }
            stopOnePart(writer: writer)
            writeVideoInput.markAsFinished()
            writeAudioInput.markAsFinished()
        }
    }
    
    /// 切换摄像头
    /// - Parameter camera: 前置 `front`、后置 `back`
    public func switchCamera(to camera: Camera) {
        collector.switchCamera(to: camera)
    }
    
    
    /// 设置是否静音录制。若想设置全局静音，需要在开始录制前设置为 `true`
    /// - Parameter mute: 静音
    public func setMute(_ mute: Bool) {
        isMute = mute
    }
    
    /// 获取录制总时长
    /// - Returns: 时长
    public func recordDuration() -> TimeInterval {
         CMTimeGetSeconds(duration)
    }
    
    /// 导出视频
    /// - Parameters:
    ///   - outputPath: 导出的路径
    ///   - complication: 导出结果回调
    public func exportRecord(outputPath: String, complication: @escaping (Bool) -> Void) throws {
        try partsManager.mixtureAllParts(outputPath: outputPath, complication: { [weak self] asset in
            if !FileManager.default.fileExists(atPath: outputPath) {
                try VideoExport.exportVideo(assetURL: nil, asset: asset, outputURL: outputPath.fileURL, filter: collector.filter) { finished in
                    if finished {
                        self?.partsManager.deleteAllParts()
                    }
                    complication(finished)
                }
            } else {
                throw VideoSessionError.Export.fileExists
            }
        })
    }
    
    
    /// 拍照。拍照可在录制的任何阶段进行
    /// - Parameter callback: 回调生成的照片
    public func takePhoto(callback: @escaping (_ photo: UIImage) -> Void) {
        photoCallback = callback
    }
}

extension VideoRecord {
    private func addOnePart() throws {
        let url = URL(fileURLWithPath: partsManager.autoincrementPath)
        print("start record in url: \(url)")
        // 初始化片段录制器
        let part = try VideoPartsManager.RecordPart(url: url, videoInput: writeVideoInput, audioInput: writeAudioInput)
        partsManager.add(part: part)
    }
    
    private func stopOnePart(writer: AVAssetWriter) {
        if writer.status == .writing {
            writer.finishWriting {
                DispatchQueue.main.async {
                    self.delegate?.didFinishPartRecord(outputURL: writer.outputURL)
                }
            }
        } else {
            DispatchQueue.main.async {
                self.delegate?.didFinishPartRecord(outputURL: writer.outputURL)
            }
        }
    }
}

extension VideoRecord: VideoCollectorDelegate {
    public func captureOutput(_ outputImage: CGImage?, didOutput sampleBuffer: CMSampleBuffer) {
        guard let callback = photoCallback else {
            return
        }
        if let outputImage = outputImage {
            photoCallback = nil
            DispatchQueue.main.async {
                callback(UIImage(cgImage: outputImage))
            }
        }
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isRecording else {
            return
        }
        guard !isPause else {
            return
        }
        guard let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer)  else {
            return
        }
    
        let type = CMFormatDescriptionGetMediaType(formatDesc)
        
        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let dur = CMSampleBufferGetDuration(sampleBuffer)
        
        
        // 修正暂停的时长
        if interrupt {
            interrupt = false
            pauseOffsetTime = pauseOffsetTime + (pts - lastInputVideoEndTime)
            print("pause offset dur is: \(CMTimeGetSeconds(pauseOffsetTime))")
        }
        
        // 记录最后一次录制的时间戳
        var endPts = pts
        if dur.value > 0 && dur.isValid {
            endPts = CMTimeAdd(pts, dur)
        }
        if type == kCMMediaType_Video {
            lastInputVideoEndTime = endPts
        } else if type == kCMMediaType_Audio {
            lastInputAudioEndTime = endPts
        }
        
        // 计算录制时长
        if type == kCMMediaType_Video {
            if startRecordTime.value == 0 {
                startRecordTime = pts
            }
            let recordTime = CMTimeSubtract(pts - pauseOffsetTime, startRecordTime)
            let recordSeconds = CMTimeGetSeconds(recordTime)
            duration = CMTimeAdd(duration, recordTime)
            if config.maxRecordedDuration > 0 && recordSeconds > config.maxRecordedDuration {
                print("The maximum time limit is reached")
                stopRecord()
                 return
            }
            DispatchQueue.main.async {
                self.delegate?.didRecording(seconds: recordSeconds)
            }
        }
        
        if let writer = partsManager.currentPart?.writer {
            guard CMSampleBufferDataIsReady(sampleBuffer) else {
                return
            }
            if writer.status == .unknown && type == kCMMediaType_Video {
                if writer.startWriting() {
                    print("start the first recording")
                    writer.startSession(atSourceTime: pts)
                    DispatchQueue.main.async {
                        self.delegate?.didStartPartRecord(outputURL: writer.outputURL)
                    }
                }
            }
            
            if writer.status == .failed {
                print("write failed[\(type==kCMMediaType_Video ? "video":"audio")] with error: \(String(describing: writer.error))")
                writer.cancelWriting()
                stopRecord()
                return
            }
            if CMSampleBufferDataIsReady(sampleBuffer) {
                if type == kCMMediaType_Video {
                    if writeVideoInput.isReadyForMoreMediaData {
                        writeVideoInput.append(sampleBuffer)
                    }
                } else if type == kCMMediaType_Audio {
                    if !isMute && writeAudioInput.isReadyForMoreMediaData {
                        writeAudioInput.append(sampleBuffer)
                    }
                }
            } else {
                print("buffer is invalid")
            }
        }
    }
}

