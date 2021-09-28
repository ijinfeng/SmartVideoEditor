//
//  VideoSessionError.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/9/28.
//

import UIKit

public enum VideoSessionError: Error {
    
    /// 初始化失败
    case initfail(errorMsg: String)
    
    public enum Record: Error {
        /// 视频录制存放地址错误
        case outputRecordPathError
        /// 没有打开摄像头
        case unOpenCamera
        /// 没有打开麦克风
        case unOpenMicrophone
    }
    
    public enum Collector: Error {
        case updateDevice
    }
    
    public enum Export: Error {
        /// 混合轨道失败
        case mixtureTrack
        /// 文件已存在
        case fileExists
        /// 资源文件为空
        case assetEmpty
    }
}
