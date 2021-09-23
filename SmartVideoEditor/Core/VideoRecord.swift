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
    private let collector = VideoCollector(config: VideoCollectorConfig())
    
    /// 视频录制的存放地址
    private var recordSavePath: String?
    
    /// 视频片段管理
    public let partsManager = VideoPartsManager()

    private let fileOutput = AVCaptureMovieFileOutput()
    
    public var isRecording: Bool {
        fileOutput.isRecording
    }
    
    public init(config: VideoRecordConfig) {
        self.config = config
        if collector.session.canAddOutput(fileOutput) {
            collector.session.addOutput(fileOutput)
        }
        fileOutput.maxRecordedDuration = CMTime.init(seconds: config.maxRecordedDuration, preferredTimescale: 1)
    }
    
    public func startCollect(preview : UIView?) {
        collector.startCollect(preview: preview)
    }
    
    public func stopCollect() {
        collector.stopCollcet()
    }
    
    @discardableResult
    public func startRecord() -> VideoRecord.RecordError {
        startRecord(in: nil)
    }
    
    /// 开始录制
    /// - Parameter videoPath: 录制输出路径
    /// - Returns: 录制状态
    @discardableResult
    public func startRecord(in videoPath: String?) -> VideoRecord.RecordError {
        if let path = videoPath {
            recordSavePath = path
        } else {
            recordSavePath = VideoRecordConfig.defaultRecordPath
        }
        print("record path=\(recordSavePath ?? "")")
        if recordSavePath?.count == 0 {
            return .videoPathError
        }
        let url = URL.init(fileURLWithPath: recordSavePath!)
        fileOutput.startRecording(to: url, recordingDelegate: self)
        
        return .noError
    }
    
    public func resume() {
        
    }
    
    /// 每次暂停，都会生成一个视频片段
    public func pauseRecord() {
        
    }
    
    public func stopRecord() {
        fileOutput.stopRecording()
    }
    
    public func switchCamera(to camera: VideoCollectorConfig.Camera) {
        collector.switchCamera(to: camera)
    }
    
    
    /// 设置是否静音录制
    /// - Parameter mute: 静音
    public func setMute(_ mute: Bool) {
        
    }
}


public extension VideoRecord {
    enum RecordError {
        /// 没有错误
        case noError
        /// 正在录制
        case recording
        /// 初始化失败
        case initfail(errorMsg: String)
        /// 视频录制存放地址错误
        case videoPathError
        /// 没有打开摄像头
        case unOpenCamera
        /// 没有打开麦克风
        case unOpenMicrophone
    }
}

extension VideoRecord: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("=========start record=========")
    }
    
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("=========stop record=========")
        
        
        
    }
}
