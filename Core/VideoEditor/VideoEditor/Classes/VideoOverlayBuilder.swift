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
    
    fileprivate let contentsLayer: CALayer!
    private var innerOverlayId: OverlayId!
    fileprivate var overlayMap: [OverlayId: CALayer] = [:]
    fileprivate var videoOverlayMap: [OverlayId: VideoOverlay] = [:]
    
    public init(playerItem: AVPlayerItem) {
        self.playerItem = playerItem
        syncLayer = AVSynchronizedLayer(playerItem: playerItem)
        contentsLayer = CALayer()
        contentsLayer.isGeometryFlipped = false
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
        let Overlay = VideoOverlayText(text: text, rect: rect)
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
        let Overlay = VideoOverlayImage(image: image, rect: rect)
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
        let Overlay = VideoOverlayGif(filePath: filePath, rect: rect)
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
        videoOverlayMap[overlay.overlayId] = overlay
        
        // 这句必须加上，否则每个首次添加贴图都会加不上去
        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        defer {
            CATransaction.commit()
        }
        
        let contentlayer = overlay.layerOfContent()
        contentlayer.isHidden = true
        contentlayer.frame = overlay.rectOfContent()
        contentsLayer.addSublayer(contentlayer)
        overlayMap[overlay.overlayId] = contentlayer
        
        // 添加显示动画
        setOverlayActivityTime(overlayId: overlay.overlayId, overlayLayer: contentlayer, at: timeRange)
        
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
        videoOverlayMap.removeValue(forKey: overlayId)
    }
    
    
    /// 根据当前的`AVPlayerItem`创建一个新的`AVMutableVideoComposition`对象
    /// - Returns: AVMutableVideoComposition
    func getVideoComposition() -> AVMutableVideoComposition {
        let asset = playerItem.asset
        let videoComposition = AVMutableVideoComposition(propertiesOf: asset)
        let duration = asset.duration
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            return videoComposition
        }
        
        var instructions: [AVMutableVideoCompositionInstruction] = []
        let videoInstruction = AVMutableVideoCompositionInstruction()
        videoInstruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction.init(assetTrack: videoTrack)
        videoInstruction.layerInstructions = [videoLayerInstruction]
        instructions.append(videoInstruction)
        
        videoComposition.instructions = instructions
        videoComposition.renderSize = videoTrack.naturalSize
        videoComposition.frameDuration = CMTime.init(value: 1, timescale: 30)
        
        return videoComposition
    }
    
    func getMixComposition() -> AVMutableComposition {
        let asset = playerItem.asset
        let composition = AVMutableComposition()
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            return composition
        }
        let videoComTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        try? videoComTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            let audioComTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            try? audioComTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: audioTrack, at: .zero)
        }
        return composition
    }
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
    
    func setOverlayActivityTime(overlayId: OverlayId, overlayLayer: CALayer, at timeRange: CMTimeRange) {
        guard timeRange.duration != .zero else {
            return
        }
        let an = CABasicAnimation.init(keyPath: "hidden")
        an.fromValue = false
        an.toValue = false
        an.beginTime = CMTimeGetSeconds(timeRange.start)
        an.duration = CMTimeGetSeconds(timeRange.duration)
        an.isRemovedOnCompletion = false
        overlayLayer.add(an, forKey: "hidden_\(overlayId)")
    }
}

// MARK: 为Layer添加铁贴纸
public extension CALayer {
    func apply(builder: VideoOverlayBuilder) {
        builder.syncLayer.frame = self.bounds
        builder.contentsLayer.frame = builder.syncLayer.bounds
        builder.syncLayer.addSublayer(builder.contentsLayer)
        addSublayer(builder.syncLayer)
    }
}

// MARK: 为导出的视频添加贴图
public extension AVMutableVideoComposition {
    func apply(builer: VideoOverlayBuilder) {
        let videoLayer = CALayer()
        videoLayer.masksToBounds = true
        let animationLayer = CALayer()
        animationLayer.isGeometryFlipped = true
        let renderSize = self.renderSize
        let renderRect = CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height)
        
        animationLayer.addSublayer(videoLayer)
        videoLayer.frame = renderRect
        animationLayer.frame = renderRect
        
        // 添加贴图layer和动画
        for (overId, overlay) in builer.videoOverlayMap {
            let contentlayer = overlay.layerOfContent()
            contentlayer.isHidden = true
            // 这个是相对屏幕的位置，显示在视频上需要转换
            // TODO: jinfeng
            let contentRect = overlay.rectOfContent()
            let screenSize = UIScreen.main.bounds.size
            let scale = screenSize.width / renderSize.width
            let realRect = CGRect(x: 0 , y: 0, width: contentRect.width / scale, height: contentRect.height / scale)
            contentlayer.bounds = realRect
            contentlayer.position = CGPoint(x: renderSize.width - contentRect.midX, y: contentRect.midY)
            animationLayer.addSublayer(contentlayer)
            
            // 注意 `animationLayer` 的尺寸
            // contentLayer: <CALayer: 0x283860860>, frame: (10.0, 60.0, 60.0, 60.0)
//        animationLayer: <CALayer: 0x283860020>, frame: (0.0, 0.0, 1024.0, 1504.0)
            
            builer.setOverlayActivityTime(overlayId: overId, overlayLayer: contentlayer, at: overlay.timeRange)
            
            if let showLayer = builer.overlayMap[overId] {
                let anKeys = showLayer.animationKeys() ?? []
                for key in anKeys {
                    if let an = showLayer.animation(forKey: key) {
                        contentlayer.add(an.copy() as! CAAnimation, forKey: key)
                    }
                }
            }
        }
        
        animationTool = AVVideoCompositionCoreAnimationTool.init(postProcessingAsVideoLayer: videoLayer, in: animationLayer)
    }
}
