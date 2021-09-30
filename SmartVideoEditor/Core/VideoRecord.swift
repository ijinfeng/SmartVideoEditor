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
    /// 是否正在录制
    public private(set) var isRecording: Bool = false
    /// 是否静音
    public private(set) var isMute: Bool = false
    
    public weak var delegate: VideoRecordDelegate?
    
    /// 上一次写入的时间
    private var lastInputTime: CMTime = .zero
    
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
            // 声道数
            AVNumberOfChannelsKey: 1,
            // 采样率
            AVSampleRateKey: 44100,
            // 码率
            AVEncoderBitRateKey: 128000
        ]
        writeAudioInput = AVAssetWriterInput.init(mediaType: .audio, outputSettings: audioSetting, sourceFormatHint: nil)
        writeAudioInput.expectsMediaDataInRealTime = true
        
        super.init()
        collector.delegate = self
        partsManager.filter = collector.filter
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
        
        if config.alwaysSinglePart {
            partsManager.resetPart()
        }
        
        try addOnePart()
    }
    
    public func resume() throws {
        print("resume record")
        isPause = false
        
//        try addOnePart()
    }
    
    /// 每次暂停，都会生成一个视频片段
    public func pauseRecord() {
        print("pause record")
        isPause = true
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
        lastInputTime = CMTime.zero
        if let writer = partsManager.currentPart?.writer {
            writer.finishWriting {
                self.delegate?.didFinishPartRecord(outputURL: writer.outputURL)
            }
        }
    }
    
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
        try partsManager.mixtureAllParts(outputPath: outputPath, complication: { [weak self] finished in
            if finished {
                self?.partsManager.deleteAllParts()
            }
            complication(finished)
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
        
        if let writer = partsManager.currentPart?.writer {
            
            let startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            lastInputTime = startTime
            
            print(lastInputTime)
            
            if writer.status == .unknown {
                if writer.startWriting() {
                    print("start the first recording")
                    writer.startSession(atSourceTime: startTime)
                    delegate?.didStartPartRecord(outputURL: writer.outputURL)
                }
            }
            
            if writer.status == .failed {
                print("write failed with error: \(String(describing: writer.error))")
                writer.cancelWriting()
                return
            }
            
            if type == kCMMediaType_Video {
                if writeVideoInput.isReadyForMoreMediaData {
                    writeVideoInput.append(sampleBuffer)
                }
            } else if type == kCMMediaType_Audio {
                if !isMute && writeAudioInput.isReadyForMoreMediaData {
                    writeAudioInput.append(sampleBuffer)
                }
            }
        }
    }
}

