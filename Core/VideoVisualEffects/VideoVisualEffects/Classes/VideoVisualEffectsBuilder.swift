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
    
    @discardableResult func insert(text: NSAttributedString, rect: CGRect, timeRange: CMTimeRange, animation handler: OverlapAnimatable?) -> OverlapId {
        let overlap = TextOverlap(text: text, rect: rect)
        return insert(overlap: overlap, timeRange: timeRange, animation: handler)
    }
    
    @discardableResult func insert(image: UIImage, rect: CGRect, timeRange: CMTimeRange, animation handler: OverlapAnimatable?) -> OverlapId {
        let overlap = ImageOverlap(image: image, rect: rect)
        return insert(overlap: overlap, timeRange: timeRange, animation: handler)
    }
    
    @discardableResult func insert(overlap: VideoOverlap, timeRange: CMTimeRange, animation handler: OverlapAnimatable?) -> OverlapId {
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
    
    /// 溢出某一贴图
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
        guard let overlapId = innerOverlapId else {
            return resetOverlapId()
        }
        innerOverlapId += 1
        return overlapId
    }
    
    func resetOverlapId() -> OverlapId {
        innerOverlapId = 0
        return innerOverlapId
    }
    
    func setOverlapActivityTime(overlapId: OverlapId, at timeRange: CMTimeRange) {
        print("显示----- \(CMTimeRangeShow(timeRange))")
        let an = CABasicAnimation.init(keyPath: "hidden")
        an.fromValue = false
        an.toValue = false
        an.beginTime = CMTimeGetSeconds(timeRange.start)
        an.duration = CMTimeGetSeconds(timeRange.duration)
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
