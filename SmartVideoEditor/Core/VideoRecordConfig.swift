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
}

extension VideoRecordConfig {
    public static let defaultRecordOutputDirPath: String =
        NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/record/"
    
    public static let recordPartsDirPath: String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/record/parts/"
}
