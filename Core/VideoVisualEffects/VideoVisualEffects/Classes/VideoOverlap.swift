//
//  VideoOverlap.swift
//  VideoVisualEffects
//
//  Created by jinfeng on 2021/10/27.
//

import UIKit
import CoreMedia

public typealias OverlapId = UInt

/// 贴图抽象类
public class VideoOverlap {
    /// 贴图的唯一标识，初始化为0即可
    public var overlapId: OverlapId = 0
    
    public var timeRange: CMTimeRange = .zero
    
    /// 返回贴图的位置
    /// - Returns: CGRect
    open func rectOfContent() -> CGRect {
        .zero
    }
    
    /// 返回贴图的展示Layer
    /// - Returns: CALayer
    open func layerOfContent() -> CALayer {
        CALayer()
    }
}

