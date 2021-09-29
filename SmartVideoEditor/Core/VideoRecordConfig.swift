//
//  VideoRecordConfig.swift
//  VideoRecordConfig
//
//  Created by jinfeng on 2021/9/23.
//

import UIKit

public class VideoRecordConfig: NSObject {
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
}

public enum VideoPixels {
    case p480
    case p540
    case p720
    case p1080
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
