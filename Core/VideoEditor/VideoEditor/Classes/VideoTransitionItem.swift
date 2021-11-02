//
//  TransitionItem.swift
//  VideoTransition
//
//  Created by jinfeng on 2021/10/25.
//

import UIKit
import AVFoundation

/// 视频过渡对象
/// 每个过渡对象都包含两个相交的资源
public class VideoTransitionItem: NSObject {
    public let fromAsset: AVAsset!
    public let toAsset: AVAsset!
    
    init(asset from: AVAsset, to: AVAsset) {
        fromAsset = from
        toAsset = to
    }
    
    /// 与上一个视频的相交时间
    public var intersectionTime: CMTime = .zero 
    
    /// 转场过渡动画
    public enum Transition {
        /// 溶解
        case dissolve
        /// 推入
        case push
        /// 擦除
        case wipe
    }
    public var type: Transition = .dissolve
}
