//
//  VideoCollectorConfig.swift
//  SmartVideoEditor
//
//  Created by JinFeng on 2021/9/20.
//

import UIKit
import AVFoundation

public class VideoCollectorConfig: NSObject {
    /// 是否允许点击曝光聚焦，默认值：true
    public var focusPoint: CGPoint?
    /// 是否自动对焦
    public var autoFocus = true
    /// 是否允许双指手势放大预览画面，默认值：true
    public var enableZoom = true
 
    public var mirrorType: MirrorType = .auto
    
    /// 视频采样帧率，默认值：15FPS
    public var videoFPS: Int32 = 15
    
    public var videoQuality: AVCaptureSession.Preset = .high
    
    /// 摄像头位置
    public var camera: Camera = .back
    
    /// 打开闪光灯
    public var toggleTorch = false
    
    /// 视频方向
    public var videoOrientation: Orientation = .portrait
}

public enum Camera {
    /// 前置
    case front
    /// 后置
    case back
}

public enum MirrorType {
    /// 即前置摄像头镜像，后置摄像头不镜像
    case auto
    /// 不镜像
    case none
    /// 镜像
    case mirror
}

public enum Orientation {
    case portrait

    case portraitUpsideDown

    case landscapeRight

    case landscapeLeft
}
