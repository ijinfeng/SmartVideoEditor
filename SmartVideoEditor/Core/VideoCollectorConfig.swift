//
//  VideoCollectorConfig.swift
//  SmartVideoEditor
//
//  Created by JinFeng on 2021/9/20.
//

import UIKit

public class VideoCollectorConfig: NSObject {
    /// 是否允许点击曝光聚焦，默认值：true
    public var touchFocus = true
    /// 是否允许双指手势放大预览画面，默认值：true
    public var enableZoom = true
 
    public enum MirrorType {
        /// 即前置摄像头镜像，后置摄像头不镜像
        case auto
        /// 不镜像
        case none
        /// 镜像
        case mirror
    }
    public var mirrorType: MirrorType = .auto
    
    /// 视频帧率，默认值：15FPS
    public var videoFPS: UInt8 = 15
    
    public enum VideoQuality {
        case q_360_640
        case q_540_960
        case q_720_1280
        case q_1080_1920
        case q_2160_3840
    }
    public var videoQuality: VideoQuality = .q_540_960
    
    public enum Camera {
        /// 前置
        case front
        /// 后置
        case back
    }
    /// 摄像头位置
    public var switchCamera: Camera = .back
    
    /// 打开闪光灯
    public var toggleTorch = false
}



