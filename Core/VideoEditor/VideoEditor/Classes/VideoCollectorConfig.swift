//
//  VideoCollectorConfig.swift
//  SmartVideoEditor
//
//  Created by JinFeng on 2021/9/20.
//

import UIKit
import AVFoundation

public class VideoCollectorConfig: NSObject {
    /// 是否允许手动曝光聚焦
    public var touchFocus = true
    
    /// 是否允许双指手势放大预览画面，默认值：true
    public var enableZoom = true
    
    /// 画面镜像
    public var mirrorType: MirrorType = .auto
    
    /// 视频采样帧率，默认值：15FPS
    public var videoFPS: Float64 = 15
    
    /// 分辨率、质量
    public var videoQuality: AVCaptureSession.Preset = .high
    
    /// 摄像头位置
    public var camera: Camera = .back
    
    /// 打开闪光灯
    public var toggleTorch: Torch = .off
    
    /// 视频方向
    public var videoOrientation: AVCaptureVideoOrientation = .portrait
    
    /// 视频是否支持自动旋转
    public var orientationType: OrientationType = .auto
}

public enum Camera {
    /// 前置
    case front
    /// 后置
    case back
}

/// 镜像模式
public enum MirrorType {
    /// 即前置摄像头镜像，后置摄像头不镜像
    case auto
    /// 不镜像
    case no
    /// 镜像
    case mirror
}

/// 闪光灯
public enum Torch {
    /// 自动，根据光线判断
    case auto
    /// 总是开启
    case on
    /// 总是关闭
    case off
}


public enum OrientationType {
    /// 自动根据屏幕方向旋转
    case auto
    /// 固定方向，需要主动设置`videoOrientation`
    case still
}


extension UIDevice {
    class func currentOrientation() -> AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .portrait:
            return AVCaptureVideoOrientation.portrait
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeRight
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeLeft
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        default:
            return AVCaptureVideoOrientation.portrait
        }
    }
}
