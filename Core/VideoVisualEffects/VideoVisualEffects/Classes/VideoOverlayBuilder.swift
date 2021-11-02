//
//  VideoVisualEffectsBuilder.swift
//  VideoVisualEffects
//
//  Created by jinfeng on 2021/10/27.
//

import UIKit
import AVFoundation

/// 贴图构造器
public class VideoOverlayBuilder: NSObject {

    public let playerItem: AVPlayerItem!
    public let syncLayer: AVSynchronizedLayer!
    
    private let contentsLayer: CALayer!
    private var innerOverlayId: OverlayId!
    private var overlayMap: [OverlayId: CALayer] = [:]
    
    public init(playerItem: AVPlayerItem) {
        self.playerItem = playerItem
        syncLayer = AVSynchronizedLayer(playerItem: playerItem)
        contentsLayer = CALayer()
        super.init()
        innerOverlayId = resetOverlayId()
    }
    
    deinit {
        print("= VideoVisualEffectsBuilder deinit =")
    }
}

// MARK: Public APi
public extension VideoOverlayBuilder {
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
        return insert(overlay: Overlay, timeRange: timeRange, animation: handler)
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
        return insert(overlay: Overlay, timeRange: timeRange, animation: handler)
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
        return insert(overlay: Overlay, timeRange: timeRange, animation: handler)
    }
    
    /// 插入贴图
    /// - Parameters:
    ///   - Overlay: 贴图对象
    ///   - timeRange: 需要展示的时间范围
    ///   - handler: 插入动画
    /// - Returns: 贴图id
    @discardableResult func insert(overlay: VideoOverlay, timeRange: CMTimeRange, animation handler: OverlayAnimatable? = nil) -> OverlayId {
        overlay.overlayId = autoIncreaseOverlayId()
        overlay.timeRange = timeRange
        
        // 这句必须加上，否则每个首次添加贴图都会加不上去
        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        defer {
            CATransaction.commit()
        }
        
        let contentlayer = overlay.layerOfContent()
        contentlayer.isHidden = true
        contentlayer.frame = overlay.rectOfContent()
        syncLayer.addSublayer(contentlayer)
        overlayMap[overlay.overlayId] = contentlayer
        
        
        // 添加显示动画
        setOverlayActivityTime(overlayId: overlay.overlayId, at: timeRange)
        
        // 外部动画
        if let handler = handler {
            let OverlayAns = handler(timeRange.start, timeRange.duration)
            for i in 0..<OverlayAns.count {
                let OverlayAn = OverlayAns[i]
                OverlayAn.isRemovedOnCompletion = false
                contentlayer.add(OverlayAn, forKey: "Overlay_\(overlay.overlayId)_\(i)")
            }
        }
        
        return overlay.overlayId
    }
    
    /// 移除某一贴图
    /// - Parameter OverlayId: 贴图id
    func removeOverlay(_ overlayId: OverlayId) {
        if let overlayLayer = overlayMap[overlayId] {
            overlayLayer.removeFromSuperlayer()
            overlayMap.removeValue(forKey: overlayId)
        }
    }
    
//    func getVideoComposition() -> AVMutableVideoComposition {
//        let videoComposition = AVMutableVideoComposition()
//        videoComposition.renderSize =
//    }
}

// MARK: Private API
private extension VideoOverlayBuilder {
    func autoIncreaseOverlayId() -> OverlayId {
        innerOverlayId += 1
        return innerOverlayId
    }
    
    func resetOverlayId() -> OverlayId {
        innerOverlayId = .invalidId
        return innerOverlayId
    }
    
    func setOverlayActivityTime(overlayId: OverlayId, at timeRange: CMTimeRange) {
        guard timeRange.duration != .zero else {
            return
        }
        let an = CABasicAnimation.init(keyPath: "hidden")
        an.fromValue = false
        an.toValue = false
        an.beginTime = CMTimeGetSeconds(timeRange.start)
        an.duration = CMTimeGetSeconds(timeRange.duration)
        an.isRemovedOnCompletion = false
        
        if let overlay = overlayMap[overlayId] {
            overlay.add(an, forKey: "hidden_\(overlayId)")
        }
    }
}

// MARK: 为Layer添加动效
public extension CALayer {
    func apply(builder: VideoOverlayBuilder) {
        builder.syncLayer.frame = self.bounds
        self.addSublayer(builder.syncLayer)
    }
}

// MARK: 为导出的视频添加贴图
public extension AVMutableVideoComposition {
    func apply(builer: VideoOverlayBuilder) {
        let videoLayer = CALayer()
        let presentLayer = CALayer()
        let renderRect = CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height)
        builer.syncLayer.frame = renderRect
        videoLayer.frame = renderRect
        presentLayer.addSublayer(videoLayer)
        presentLayer.addSublayer(builer.syncLayer)
        
        animationTool = AVVideoCompositionCoreAnimationTool.init(postProcessingAsVideoLayer: videoLayer, in: presentLayer)
    }
}
