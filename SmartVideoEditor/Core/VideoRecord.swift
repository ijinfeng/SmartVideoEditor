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
    
    static let shared = VideoRecord(config: VideoRecordConfig())
    
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
    /// 是否有中断过
    private var videoInterrupt = false
    private var audioInterrupt = false
    /// 是否正在录制
    public private(set) var isRecording: Bool = false
    /// 是否静音
    public private(set) var isMute: Bool = false
    
    public weak var delegate: VideoRecordDelegate?
    
    /// 记录最后一帧的结束时间，也就是下一帧的开始时间
    private var lastInputVideoEndTime: CMTime = .zero
    private var lastInputAudioEndTime: CMTime = .zero
    /// 暂停的时间
    private var pauseVideoOffsetTime: CMTime = .zero
    private var pauseAudioOffsetTime: CMTime = .zero
    /// 开始录制的时间
    private var startRecordTime: CMTime = .zero
    
    
    public init(config: VideoRecordConfig) {
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
    public func startCollect(preview : UIView?) {
        collector.startCollect(preview: preview)
    }
    
    public func stopCollect() {
        collector.stopCollcet()
    }
    
    public func startRecord() throws {
        try startRecord(in: nil)
    }
    
    /// 开始录制
    /// - Parameter videoPath: 录制输出路径
    /// - Returns: 录制状态
    public func startRecord(in outputVideoPath: String?) throws {
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
        videoInterrupt = false
        audioInterrupt = false
        lastInputVideoEndTime = .zero
        lastInputAudioEndTime = .zero
        startRecordTime = .zero
        pauseVideoOffsetTime = .zero
        pauseAudioOffsetTime = .zero
        
        if config.alwaysSinglePart {
            partsManager.resetPart()
        }
        
        try addOnePart()
    }
    
    public func resume() throws {
        guard isPause else {
            return
        }
        print("resume record")
        isPause = false
        
//        try addOnePart()
    }
    
    /// 每次暂停，都会生成一个视频片段
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
        videoInterrupt = true
        audioInterrupt = true
//        if let writer = partsManager.currentPart?.writer {
//            writer.finishWriting {
//                self.delegate?.didFinishPartRecord(outputURL: writer.outputURL)
//            }
//        }
    }
    
    public func stopRecord() {
        guard isPause || isRecording else {
            print("aleady stop record")
            return
        }
        print("stop record")
        isRecording = false
        isPause = false
        if let writer = partsManager.currentPart?.writer {
            if writer.status == .writing {
                writer.finishWriting {
                    self.delegate?.didFinishPartRecord(outputURL: writer.outputURL)
                }
                writeVideoInput.markAsFinished()
                writeAudioInput.markAsFinished()
            }
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
}

extension VideoRecord {
    private func addOnePart() throws {
        let url = URL(fileURLWithPath: partsManager.autoincrementPath)
        print("start record in url: \(url)")
        // 初始化片段录制器
        let part = try VideoPartsManager.RecordPart(url: url, videoInput: writeVideoInput, audioInput: writeAudioInput)
        partsManager.add(part: part)
    }
    
    // https://blog.csdn.net/wang631106979/article/details/51498009
    private func adjustOffsetTimeIfNeeded(type: CMMediaType, sampleBuffer: CMSampleBuffer) -> CMSampleBuffer {
        // TODO: 修改sampleBuffer的pts后，会导致写入不成功
        // write failed with error: Optional(Error Domain=AVFoundationErrorDomain Code=-11800 "The operation could not be completed" UserInfo={NSLocalizedFailureReason=An unknown error occurred (-16364), NSLocalizedDescription=The operation could not be completed, NSUnderlyingError=0x2800e33f0 {Error Domain=NSOSStatusErrorDomain Code=-16364 "(null)"}})
        var useSampleBuffer = sampleBuffer
        var pts = CMSampleBufferGetPresentationTimeStamp(useSampleBuffer)
        if videoInterrupt && type == kCMMediaType_Video {
            videoInterrupt = false
            let last = lastInputVideoEndTime
            if last.flags.contains(.valid) {
                if pauseVideoOffsetTime.flags.contains(.valid) {
                    pts = CMTimeSubtract(pts, pauseVideoOffsetTime)
                }
                let offset = CMTimeSubtract(pts, last)
                if pauseVideoOffsetTime.value == 0 {
                    pauseVideoOffsetTime = offset
                } else {
                    pauseVideoOffsetTime = CMTimeAdd(pauseVideoOffsetTime, offset)
                }
            }
            lastInputVideoEndTime.flags = CMTimeFlags.init(rawValue: 0)
        }
        if audioInterrupt && type == kCMMediaType_Audio {
            audioInterrupt = false
            let last = lastInputAudioEndTime
            if last.flags.contains(.valid) {
                if pauseAudioOffsetTime.flags.contains(.valid) {
                    pts = CMTimeSubtract(pts, pauseAudioOffsetTime)
                }
                let offset = CMTimeSubtract(pts, last)
                if pauseAudioOffsetTime.value == 0 {
                    pauseAudioOffsetTime = offset
                } else {
                    pauseAudioOffsetTime = CMTimeAdd(pauseAudioOffsetTime, offset)
                }
            }
            lastInputAudioEndTime.flags = CMTimeFlags.init(rawValue: 0)
        }
        
        var offsetTime: CMTime = .zero
        if type == kCMMediaType_Video {
            offsetTime = pauseVideoOffsetTime
        } else if type == kCMMediaType_Audio {
            offsetTime = pauseAudioOffsetTime
        }
//        let offsetTime = pauseAudioOffsetTime
        
        if offsetTime.value > 0 {
            var count: CMItemCount = 0
            CMSampleBufferGetSampleTimingInfoArray(useSampleBuffer, entryCount: 0, arrayToFill: nil, entriesNeededOut: &count)
            let timingInfo = UnsafeMutablePointer<CMSampleTimingInfo>.allocate(capacity: count)
            for i in 0..<count {
                CMSampleBufferGetSampleTimingInfo(useSampleBuffer, at: i, timingInfoOut: timingInfo)
                timingInfo.pointee.presentationTimeStamp = CMTimeSubtract(timingInfo.pointee.presentationTimeStamp, offsetTime)
                timingInfo.pointee.decodeTimeStamp = CMTimeSubtract(timingInfo.pointee.decodeTimeStamp, offsetTime)
            }
            let s = UnsafeMutablePointer<CMSampleBuffer?>.allocate(capacity: 1)
            CMSampleBufferCreateCopyWithNewTiming(allocator: kCFAllocatorDefault, sampleBuffer: useSampleBuffer, sampleTimingEntryCount: count, sampleTimingArray: timingInfo, sampleBufferOut: s)
            if let s = s.pointee {
                useSampleBuffer = s
            }
            free(timingInfo)
            free(s)
        }
        return useSampleBuffer
    }
}


extension VideoRecord: VideoCollectorDelegate {
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
        // 调整时间戳
        let useSampleBuffer = adjustOffsetTimeIfNeeded(type: type, sampleBuffer: sampleBuffer)
        
        let pts = CMSampleBufferGetPresentationTimeStamp(useSampleBuffer)
        let dur = CMSampleBufferGetDuration(useSampleBuffer)
        // 记录最后一次录制的时间戳
        var endPts = pts
        if dur.value > 0 {
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
            let recordTime = CMTimeSubtract(pts, startRecordTime)
            let recordSeconds = CMTimeGetSeconds(recordTime)
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
            guard CMSampleBufferDataIsReady(useSampleBuffer) else {
                return
            }
            if writer.status == .unknown && type == kCMMediaType_Video {
                if writer.startWriting() {
                    print("start the first recording")
                    writer.startSession(atSourceTime: pts)
                    delegate?.didStartPartRecord(outputURL: writer.outputURL)
                }
            }
            
            if writer.status == .failed {
                print("write failed with error: \(String(describing: writer.error))")
                writer.cancelWriting()
                stopRecord()
                return
            }
            if type == kCMMediaType_Video {
                if writeVideoInput.isReadyForMoreMediaData {
                    writeVideoInput.append(useSampleBuffer)
                }
            } else if type == kCMMediaType_Audio {
                if !isMute && writeAudioInput.isReadyForMoreMediaData {
                    writeAudioInput.append(useSampleBuffer)
                }
            }
        }
    }
}

