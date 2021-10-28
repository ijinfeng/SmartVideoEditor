//
//  VideoVisualEffectsBuilder.swift
//  VideoVisualEffects
//
//  Created by jinfeng on 2021/10/27.
//

import UIKit
import AVFoundation

public class VideoVisualEffectsBuilder: NSObject {

    private let playerItem: AVPlayerItem!
    fileprivate let syncLayer: AVSynchronizedLayer!
    
    private var innerOverlapId: OverlapId!
    private var overlapMap: [OverlapId: CALayer] = [:]
    
    public init(playerItem: AVPlayerItem) {
        self.playerItem = playerItem
        syncLayer = AVSynchronizedLayer(playerItem: playerItem)
        super.init()
        innerOverlapId = resetOverlapId()
    }
    
    deinit {
        print("= VideoVisualEffectsBuilder deinit =")
    }
}

// MARK: Public APi
public extension VideoVisualEffectsBuilder {
    typealias OverlapAnimatable = (_ begin: CMTime, _ duration: CMTime) -> [CAAnimation]
    
    /// 添加文字贴图
    /// - Parameters:
    ///   - text: 文字
    ///   - rect: 布局
    ///   - timeRange: 需要展示的时间范围
    ///   - handler: 插入动画
    /// - Returns: 贴图id
    @discardableResult func insert(text: NSAttributedString, rect: CGRect, timeRange: CMTimeRange, animation handler: OverlapAnimatable? = nil) -> OverlapId {
        let overlap = TextOverlap(text: text, rect: rect)
        return insert(overlap: overlap, timeRange: timeRange, animation: handler)
    }
    
    /// 添加图片贴图
    /// - Parameters:
    ///   - image: 图片
    ///   - rect: 布局
    ///   - timeRange: 需要展示的时间范围
    ///   - handler: 插入动画
    /// - Returns: 贴图id
    @discardableResult func insert(image: UIImage, rect: CGRect, timeRange: CMTimeRange, animation handler: OverlapAnimatable? = nil) -> OverlapId {
        let overlap = ImageOverlap(image: image, rect: rect)
        return insert(overlap: overlap, timeRange: timeRange, animation: handler)
    }
    
    /// 插入gif图
    /// - Parameters:
    ///   - filePath: 本地gif图资源路径
    ///   - rect: 布局
    ///   - timeRange: 需要展示的时间范围
    ///   - handler: 插入动画
    /// - Returns: 贴图id
    @discardableResult func insert(gif filePath: String, rect: CGRect, timeRange: CMTimeRange, animation handler: OverlapAnimatable? = nil) -> OverlapId {
        guard filePath.count > 0 else {
            return .invalidId
        }
        let overlap = GifOverlap(filePath: filePath, rect: rect)
        return insert(overlap: overlap, timeRange: timeRange, animation: handler)
    }
    
    /// 插入贴图
    /// - Parameters:
    ///   - overlap: 贴图对象
    ///   - timeRange: 需要展示的时间范围
    ///   - handler: 插入动画
    /// - Returns: 贴图id
    @discardableResult func insert(overlap: VideoOverlap, timeRange: CMTimeRange, animation handler: OverlapAnimatable? = nil) -> OverlapId {
        overlap.overlapId = autoIncreaseOverlapId()
        overlap.timeRange = timeRange
        
        let contentlayer = overlap.layerOfContent()
        contentlayer.isHidden = true
        contentlayer.frame = overlap.rectOfContent()
        syncLayer.addSublayer(contentlayer)
        overlapMap[overlap.overlapId] = contentlayer
        
        // 添加显示动画
        setOverlapActivityTime(overlapId: overlap.overlapId, at: timeRange)
        
        // 外部动画
        if let handler = handler {
            let overlapAns = handler(timeRange.start, timeRange.duration)
            for i in 0..<overlapAns.count {
                let overlapAn = overlapAns[i]
                overlapAn.isRemovedOnCompletion = false
                contentlayer.add(overlapAn, forKey: "overlap_\(overlap.overlapId)_\(i)")
            }
        }
        
        return overlap.overlapId
    }
    
    /// 移除某一贴图
    /// - Parameter overlapId: 贴图id
    func removeOverlap(_ overlapId: OverlapId) {
        if let overlapLayer = overlapMap[overlapId] {
            overlapLayer.removeFromSuperlayer()
            overlapMap.removeValue(forKey: overlapId)
        }
    }
}

// MARK: Private API
private extension VideoVisualEffectsBuilder {
    func autoIncreaseOverlapId() -> OverlapId {
        innerOverlapId += 1
        return innerOverlapId
    }
    
    func resetOverlapId() -> OverlapId {
        innerOverlapId = .invalidId
        return innerOverlapId
    }
    
    func setOverlapActivityTime(overlapId: OverlapId, at timeRange: CMTimeRange) {
        guard timeRange.duration != .zero else {
            return
        }
        // TODO: jinfeng ，`hidden` 动画添加后没有立即作用，layer没有立即显示。会不会和`calayer`的隐式动画有关系？
        print("显示----- \(CMTimeRangeShow(timeRange))")
        let an = CABasicAnimation.init(keyPath: "hidden")
        an.fromValue = false
        an.toValue = false
        an.beginTime = CMTimeGetSeconds(timeRange.start)
        an.duration = CMTimeGetSeconds(timeRange.duration)
        an.timingFunction = CAMediaTimingFunction(name: .default)
        an.isRemovedOnCompletion = false
        if let overlap = overlapMap[overlapId] {
            overlap.add(an, forKey: "hidden_\(overlapId)")
        }
    }
}

// MARK: 为Layer添加动效
public extension CALayer {
    func apply(effectsBuilder: VideoVisualEffectsBuilder) {
        effectsBuilder.syncLayer.frame = self.bounds
        self.addSublayer(effectsBuilder.syncLayer)
    }
}
