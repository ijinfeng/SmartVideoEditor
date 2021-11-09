//
//  TimeLine.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/11/9.
//

import UIKit
import AVFoundation

public class TimeLine {
    public let asset: AVAsset!
    
    public init(asset: AVAsset) {
        self.asset = asset
    }
    
    public var renderSize: CGSize = CGSize(width: 960, height: 540)
    public var renderScale: Float = 1.0
    public var frameDuration: CMTime = CMTime.init(value: 1, timescale: 30)
    
    
    public enum ContentMode {
        case scaleAspectFit
        case scaleAspectFill
        case scaleFill
    }
    public var contentMode: ContentMode = .scaleAspectFit
    
    private var eidBuilder = ElementIdentiferBuilder()
    private var overlayElementDic: [VisualElementIdentifer: OverlayProvider] = [:]
    private var specialEffectsElementDic: [VisualElementIdentifer: SpecialEffectsProvider] = [:]
}

// MARK: Public API
public extension TimeLine {
    @discardableResult func insert(element: OverlayProvider) -> VisualElementIdentifer {
        let id = eidBuilder.get()
        element.visualElementId = id
        overlayElementDic[id] = element
        return id
    }
    
    @discardableResult func insert(element: SpecialEffectsProvider) -> VisualElementIdentifer {
        let id = eidBuilder.get()
        element.visualElementId = id
        specialEffectsElementDic[id] = element
        return id
    }
}

extension TimeLine {
    func apply(source: CIImage, at time: CMTime) -> CIImage {
        var image = source
        
        // 修改视频布局显示 `contentMode`
        let t: CGAffineTransform!
        let renderRect = CGRect(origin: .zero, size: renderSize)
        switch contentMode {
        case .scaleAspectFit:
            t = CGAffineTransform.transform(rect: image.extent, aspectFit: renderRect)
        case .scaleFill:
            t = CGAffineTransform.transform(rect: image.extent, aspectFill: renderRect)
        case .scaleAspectFill:
            t = CGAffineTransform.transform(rect: image.extent, fill: renderRect)
        }
        image = image.transformed(by: t)
        
        // 处理贴纸
        overlayElementDic.values.forEach { provider in
            if CMTimeRangeContainsTime(provider.timeRange, time: time) {
                if let effectImage = provider.applyEffect(at: time) {
                    image = effectImage.composited(over: image)
                }
            }
        }
        return image
    }
}
