//
//  VideoRecordConfig.swift
//  VideoRecordConfig
//
//  Created by jinfeng on 2021/9/23.
//

import UIKit

public class VideoRecordConfig: NSObject {
    // MARK: 视频设置
    /// 录制的最大时长
    public var maxRecordedDuration: TimeInterval = 15
    /// fps
    public var videoFPS: Int32 = 15
    /// 摄像头位置
    public var camera: Camera = .back
    /// 自定义码率
    public var customBitRate: Int?
    /// 分辨率
    public var pixels: VideoPixels = .p720
    /// 是否总是以一个单一片段录制，默认为 `false`。当设置为 `true` 时，录制的全过程只有一个录制片段，当设置为 `false` 时，每次调用 `startRecord:` 将产生一个新片段
    public var alwaysSinglePart = false
    
    // MARK: 音频设置
    /// 音频采样率
    public var audioSampleRate: AudioSampleRate = .s44100
}

public enum VideoPixels {
    case p480
    case p540
    case p720
    case p1080
}

/// 音频采样率，提供4种默认采样率
public enum AudioSampleRate: Float {
    case s8000 = 8000
    case s16000 = 16000
    case s22050 = 22050
    case s44100 = 44100
}



extension VideoRecordConfig {
    func pixelsSize() -> (width: Int, height: Int) {
        switch pixels {
        case .p480:
            return (480, 640)
        case .p720:
            return (720, 1280)
        case .p540:
            return (540, 960)
        case .p1080:
            return (1080, 1920)
        }
    }
}

extension VideoRecordConfig {
    public static let defaultRecordOutputDirPath: String =
        NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/record/"
    
    public static let recordPartsDirPath: String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/record/parts/"
}
