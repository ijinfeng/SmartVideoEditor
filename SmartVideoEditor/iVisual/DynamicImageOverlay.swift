//
//  DynamicImageOverlay.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/11/10.
//

import Foundation
import CoreMedia
import CoreImage
import UIKit

public class DynamicImageOverlay: OverlayProvider {
    public var frame: CGRect = .zero
    public var timeRange: CMTimeRange = .zero
    public var visualElementId: VisualElementIdentifer = .invalid
    public let filePath: String!
    /// 每帧画面的持续时间
    public var frameDuration: TimeInterval = 0.15
    /// 播放总时长
    public var totalDuration: TimeInterval {
        frameDuration * Double(frameCount)
    }
    
    private var imageSource: CGImageSource?
    /// 总共有几帧画面
    private var frameCount: Int = 0
    
    public init(filePath: String) {
        self.filePath = filePath
        if let data = try? Data.init(contentsOf: URL(fileURLWithPath: filePath)) {
            imageSource = CGImageSourceCreateWithData(data as CFData, nil)
            if let imageSource = imageSource {
                frameCount = CGImageSourceGetCount(imageSource)
                if frameCount > 0 {
                    if let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] {
                        // 计算每一帧的延时
                        if var delayTime = properties[kCGImagePropertyGIFUnclampedDelayTime as String] as? TimeInterval {
                            if delayTime == 0 {
                                delayTime = (properties[kCGImagePropertyGIFDelayTime as String] as? TimeInterval) ?? 0.15
                            }
                            frameDuration = delayTime
                        }
                    }
                }
            }
        }
    }
    
    private init() {
        filePath = ""
    }
    
    public func applyEffect(at time: CMTime) -> CIImage? {
        let curTime = CMTimeSubtract(time, timeRange.start)
        var curTimeSeconds = CMTimeGetSeconds(curTime)
        if curTimeSeconds > totalDuration {
            // 这里需要重复播放
            curTimeSeconds -= totalDuration
        }
        var nearTime: TimeInterval = 0
        for i in 0..<frameCount {
            if nearTime >= curTimeSeconds {
                // get i
                if let imageSource = imageSource {
                    if let image = CGImageSourceCreateImageAtIndex(imageSource, i, nil) {
                        return CIImage(cgImage: image)
                    }
                }
                break
            }
            nearTime += frameDuration
        }
        // 对于播放完了，那么直接取最后一帧显示，防止出现空白
        if frameCount > 0 {
            if let imageSource = imageSource {
                if let image = CGImageSourceCreateImageAtIndex(imageSource, frameCount - 1, nil) {
                    return CIImage(cgImage: image)
                }
            }
        }
        return nil
    }
}
