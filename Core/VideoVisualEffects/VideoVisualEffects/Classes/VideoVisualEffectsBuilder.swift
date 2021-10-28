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
    
    private var innerOverlayId: OverlayId!
    private var OverlayMap: [OverlayId: CALayer] = [:]
    
    public init(playerItem: AVPlayerItem) {
        self.playerItem = playerItem
        syncLayer = AVSynchronizedLayer(playerItem: playerItem)
        super.init()
        innerOverlayId = resetOverlayId()
    }
    
    deinit {
        print("= VideoVisualEffectsBuilder deinit =")
    }
}

// MARK: Public APi
public extension VideoVisualEffectsBuilder {
    typealias OverlayAnimatable = (_ begin: CMTime, _ duration: CMTime) -> [CAAnimation]
    
    /// 添加文字贴图
    /// - Parameters:
    ///   - text: 文字
    ///   - rect: 布局
    ///   - timeRange: 需要展示的时间范围
    ///   - handler: 插入动画
    /// - Returns: 贴图id
    @discardableResult func insert(text: NSAttributedString, rect: CGRect, timeRange: CMTimeRange, animation handler: OverlayAnimatable? = nil) -> OverlayId {
        let Overlay = TextOverlay(text: text, rect: rect)
        return insert(Overlay: Overlay, timeRange: timeRange, animation: handler)
    }
    
    /// 添加图片贴图
    /// - Parameters:
    ///   - image: 图片
    ///   - rect: 布局
    ///   - timeRange: 需要展示的时间范围
    ///   - handler: 插入动画
    /// - Returns: 贴图id
    @discardableResult func insert(image: UIImage, rect: CGRect, timeRange: CMTimeRange, animation handler: OverlayAnimatable? = nil) -> OverlayId {
        let Overlay = ImageOverlay(image: image, rect: rect)
        return insert(Overlay: Overlay, timeRange: timeRange, animation: handler)
    }
    
    /// 插入gif图
    /// - Parameters:
    ///   - filePath: 本地gif图资源路径
    ///   - rect: 布局
    ///   - timeRange: 需要展示的时间范围
    ///   - handler: 插入动画
    /// - Returns: 贴图id
    @discardableResult func insert(gif filePath: String, rect: CGRect, timeRange: CMTimeRange, animation handler: OverlayAnimatable? = nil) -> OverlayId {
        guard filePath.count > 0 else {
            return .invalidId
        }
        let Overlay = GifOverlay(filePath: filePath, rect: rect)
        return insert(Overlay: Overlay, timeRange: timeRange, animation: handler)
    }
    
    /// 插入贴图
    /// - Parameters:
    ///   - Overlay: 贴图对象
    ///   - timeRange: 需要展示的时间范围
    ///   - handler: 插入动画
    /// - Returns: 贴图id
    @discardableResult func insert(Overlay: VideoOverlay, timeRange: CMTimeRange, animation handler: OverlayAnimatable? = nil) -> OverlayId {
        Overlay.OverlayId = autoIncreaseOverlayId()
        Overlay.timeRange = timeRange
        
        let contentlayer = Overlay.layerOfContent()
        contentlayer.isHidden = true
        contentlayer.frame = Overlay.rectOfContent()
        syncLayer.addSublayer(contentlayer)
        OverlayMap[Overlay.OverlayId] = contentlayer
        
        // 添加显示动画
        setOverlayActivityTime(OverlayId: Overlay.OverlayId, at: timeRange)
        
        // 外部动画
        if let handler = handler {
            let OverlayAns = handler(timeRange.start, timeRange.duration)
            for i in 0..<OverlayAns.count {
                let OverlayAn = OverlayAns[i]
                OverlayAn.isRemovedOnCompletion = false
                contentlayer.add(OverlayAn, forKey: "Overlay_\(Overlay.OverlayId)_\(i)")
            }
        }
        
        return Overlay.OverlayId
    }
    
    /// 移除某一贴图
    /// - Parameter OverlayId: 贴图id
    func removeOverlay(_ OverlayId: OverlayId) {
        if let OverlayLayer = OverlayMap[OverlayId] {
            OverlayLayer.removeFromSuperlayer()
            OverlayMap.removeValue(forKey: OverlayId)
        }
    }
}

// MARK: Private API
private extension VideoVisualEffectsBuilder {
    func autoIncreaseOverlayId() -> OverlayId {
        innerOverlayId += 1
        return innerOverlayId
    }
    
    func resetOverlayId() -> OverlayId {
        innerOverlayId = .invalidId
        return innerOverlayId
    }
    
    func setOverlayActivityTime(OverlayId: OverlayId, at timeRange: CMTimeRange) {
        guard timeRange.duration != .zero else {
            return
        }
        // TODO: jinfeng ，`hidden` 动画添加后没有立即作用，layer没有立即显示。但是不修改当前时间，继续添加就可以了。会不会和`calayer`的隐式动画有关系？
        print("显示----- \(CMTimeRangeShow(timeRange))")
        let an = CABasicAnimation.init(keyPath: "hidden")
        an.fromValue = false
        an.toValue = false
        an.beginTime = CMTimeGetSeconds(timeRange.start)
        an.duration = CMTimeGetSeconds(timeRange.duration)
        an.isRemovedOnCompletion = false

        if let Overlay = OverlayMap[OverlayId] {
            Overlay.add(an, forKey: "hidden_\(OverlayId)")
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
