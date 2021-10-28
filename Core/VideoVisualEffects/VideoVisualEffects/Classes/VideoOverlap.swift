//
//  VideoOverlap.swift
//  VideoVisualEffects
//
//  Created by jinfeng on 2021/10/27.
//

import UIKit
import CoreMedia

public typealias OverlapId = UInt
extension OverlapId {
    public static let invalidId: OverlapId = 0
}

/// 贴图抽象类
public class VideoOverlap {
    /// 贴图的唯一标识，初始化为0即可
    public var overlapId: OverlapId = .invalidId
    
    /// 展示的时间范围
    public var timeRange: CMTimeRange = .zero
    
    /// 返回贴图的位置【override】
    /// - Returns: CGRect
    open func rectOfContent() -> CGRect {
        .zero
    }
    
    /// 返回贴图的展示Layer【override】
    /// - Returns: CALayer
    open func layerOfContent() -> CALayer {
        CALayer()
    }
}

