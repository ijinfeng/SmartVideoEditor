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
    private var isPause: Bool = false
    /// 是否正在录制
    public private(set) var isRecording: Bool = false
    
    public weak var delegate: VideoRecordDelegate?
    
    public init(config: VideoRecordConfig) {
        self.config = config
        
        let screenSize = UIScreen.main.bounds.size
        var bitRate = Int(screenSize.width * screenSize.height) * 12 /*b*/
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
            AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel
        ]
        let videoSetting: [String: Any] = [
            // 编码格式
            AVVideoCodecKey: codecType!,
            // 分辨率
            AVVideoWidthKey: screenSize.width * 2,
            AVVideoHeightKey: screenSize.height * 2,
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
    }
    
    deinit {
        print("-record deinit-")
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
            throw RecordError.outputRecordPathError
        }
        
        isRecording = true
        isPause = false
        
        let url = URL(fileURLWithPath: partsManager.autoincrementPath)
        print("start record in url: \(url)")
        // 初始化片段录制器
        let part = try VideoPartsManager.RecordPart(url: url, videoInput: writeVideoInput, audioInput: writeAudioInput)
        partsManager.add(part: part)
        // 第一次录制需要清空parts目录
        
    }
    
    public func resume() {
        print("resume record")
        isPause = false
    }
    
    /// 每次暂停，都会生成一个视频片段
    public func pauseRecord() {
        print("pause record")
        isPause = true
    }
    
    public func stopRecord() {
        print("stop record")
        isRecording = false
        isPause = false
        if let writer = partsManager.currentPart?.writer {
            writer.finishWriting {
                self.delegate?.didFinishRecord(outputURL: writer.outputURL)
            }
        }
    }
    
    public func switchCamera(to camera: Camera) {
        collector.switchCamera(to: camera)
    }
    
    
    /// 设置是否静音录制
    /// - Parameter mute: 静音
    public func setMute(_ mute: Bool) {
        
    }
}

extension VideoRecord {
    public enum RecordError: Error {
        /// 初始化失败
        case initfail(errorMsg: String)
        /// 视频录制存放地址错误
        case outputRecordPathError
        /// 没有打开摄像头
        case unOpenCamera
        /// 没有打开麦克风
        case unOpenMicrophone
    }
}


extension VideoRecord: VideoCollectorDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isRecording && !isPause else {
            return
        }
        guard let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer)  else {
            return
        }
        
        let type = CMFormatDescriptionGetMediaType(formatDesc)
        
        if let writer = partsManager.currentPart?.writer {
            
            if writer.status == .unknown {
                if writer.startWriting() {
                    print("start the first recording")
                    let startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                    writer.startSession(atSourceTime: startTime)
                    delegate?.didStartRecord(outputURL: writer.outputURL)
                }
            }
            
            if writer.status == .failed {
                print("write failed with error: \(String(describing: writer.error))")
                return
            }
            
            if type == kCMMediaType_Video {
                if writeVideoInput.isReadyForMoreMediaData {
                    writeVideoInput.append(sampleBuffer)
                }
            } else if type == kCMMediaType_Audio {
                if writeAudioInput.isReadyForMoreMediaData {
                    writeAudioInput.append(sampleBuffer)
                }
            }
        }
    }
}

