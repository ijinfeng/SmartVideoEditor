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
    public var backgroundColor: UIColor?
    
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
    
    func removed(element useId: VisualElementIdentifer) {
        if overlayElementDic.has(key: useId) {
            overlayElementDic.removeValue(forKey: useId)
        }
        if specialEffectsElementDic.has(key: useId) {
            specialEffectsElementDic.removeValue(forKey: useId)
        }
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
            t = CGAffineTransform.transform(rect: image.extent, fill: renderRect)
        case .scaleAspectFill:
            t = CGAffineTransform.transform(rect: image.extent, aspectFill: renderRect)
        }
        image = image.transformed(by: t)
        if contentMode == .scaleAspectFill {
            image = image.cropped(to: renderRect)
        }
        
        // 处理贴纸
        overlayElementDic.values.forEach { provider in
            if CMTimeRangeContainsTime(provider.timeRange, time: time) {
                if var effectImage = provider.applyEffect(at: time) {
                    // 转换坐标系，默认原点在左下角
                    var fillRect = effectImage.extent.fill(to: provider.frame)
                    fillRect.origin = provider.frame.origin
                    // 当作用在 1080x1920的画布上时，由于图片尺寸为外部传入的60，因此在适配到屏幕后会出现缩小现象，因此在一开始做缩放转换的时候，就需要乘上这个屏幕的缩放比例
                    let screenScale = image.extent.width / UIScreen.main.bounds.width
                    fillRect = fillRect.scale(by: screenScale)
                    let yratio = fillRect.height / effectImage.extent.height
                    let xratio = fillRect.width / effectImage.extent.width
                    let t = CGAffineTransform.transform(rect: effectImage.extent, fill: provider.frame.scale(by: screenScale))
                        .translatedBy(x: fillRect.origin.x / xratio, y: (renderRect.height - fillRect.height - fillRect.origin.y) / yratio)
                    effectImage = effectImage.transformed(by: t)
                    image = effectImage.composited(over: image)
                }
            }
        }
        return image
    }
}
