//
//  VideoRecorder.swift
//  VideoRecorder
//
//  Created by jinfeng on 2021/9/22.
//

import UIKit
import AVFoundation

public enum RecordError {
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

/// 视频录制
public class VideoRecord: NSObject {
    
    static let shared = VideoRecord()
    
    /// 视频信息采集
    private let collector = VideoCollector(config: VideoCollectorConfig())
    
    /// 视频录制的存放地址
    private var recordSavePath: String?
    
    /// 视频片段管理
    public let partsManager = VideoPartsManager()
    
    private let write: AVAssetWriter!
    private let audioInput: AVAssetWriterInput!
    private let videoInput: AVAssetWriterInput!
    
    
    private override init() {
        
        super.init()
        
    }
    
    public func startPreview(on view: UIView) {
        collector.startCollect(preview: view)
    }
    
    public func stopPreview() {
        collector.stopCollcet()
    }
    
    
    public func startRecord() -> RecordError {
        startRecord(in: nil)
    }
    
    /// 开始录制
    /// - Parameter videoPath: 录制输出路径
    /// - Returns: 录制状态
    public func startRecord(in videoPath: String?) -> RecordError {
        if let path = videoPath {
            recordSavePath = path
        } else {
            recordSavePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/record"
        }
        print("record path=\(recordSavePath ?? "")")
        if recordSavePath?.count == 0 {
            return .videoPathError
        }
        
        return .noError
    }
    
    public func resume() {
        
    }
    
    /// 每次暂停，都会生成一个视频片段
    public func pauseRecord() {
        
    }
    
    public func stopRecord() {
        
    }
    
    public func switchCamera(to camera: VideoCollectorConfig.Camera) {
        collector.switchCamera(to: camera)
    
    }
    
    
    /// 设置是否静音录制
    /// - Parameter mute: 静音
    public func setMute(_ mute: Bool) {
        
    }
}
