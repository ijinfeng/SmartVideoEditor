//
//  GifOverlap.swift
//  VideoVisualEffects
//
//  Created by jinfeng on 2021/10/28.
//

import UIKit
import CoreMedia

public class GifOverlap: VideoOverlap {
    public private(set) var filePath: String!
    private var rect: CGRect!
    
    public init(filePath: String, rect: CGRect) {
        self.filePath = filePath
        self.rect = rect
    }
    
    public override func rectOfContent() -> CGRect {
        rect
    }
    
    open override func layerOfContent() -> CALayer {
        let gifLayer = CALayer()
        if let data = try? Data.init(contentsOf: URL(fileURLWithPath: filePath)) {
            if let imageSource = CGImageSourceCreateWithData(data as CFData, nil) {
                
                let an = CAKeyframeAnimation(keyPath: "contents")
                an.beginTime = CMTimeGetSeconds(timeRange.start)
                an.duration = CMTimeGetSeconds(timeRange.duration)
                an.isRemovedOnCompletion = false
                
                var values: [CGImage] = []
                var keyTimes: [NSNumber] = []
                var frameTimes: [TimeInterval] = []
                
                let numberOfFrames = CGImageSourceGetCount(imageSource)
                var totalTime: TimeInterval = 0
                for i in 0..<numberOfFrames {
                    if let image = CGImageSourceCreateImageAtIndex(imageSource, i, nil) {
                        if let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil) as? [String: Any] {
                            // 计算每一帧的延时
                            var delayTime = 0.15
                            if var _delayTime = properties[kCGImagePropertyGIFUnclampedDelayTime as String] as? TimeInterval {
                                if _delayTime == 0 {
                                    _delayTime = (properties[kCGImagePropertyGIFDelayTime as String] as? TimeInterval) ?? 0.15
                                }
                                delayTime = _delayTime
                            }
                            totalTime += delayTime
                            // 如果超时就抛弃后面的图片帧
                            if totalTime > CMTimeGetSeconds(timeRange.duration) {
                                break
                            }
                            frameTimes.append(delayTime)
                        }
                        values.append(image)
                    }
                }
                
                // 如果持续时间比gif的播放时间长，那么需要在播到最后一张的时候从头开始播，这时需要插入新的时间点
                var playTime: TimeInterval = 0
                var readIndex: Int = 0
                let frameTimeCount = frameTimes.count
                var realImages: [CGImage] = []
                while playTime < CMTimeGetSeconds(timeRange.duration) && frameTimeCount > 0 {
                    if readIndex >= frameTimeCount {
                        readIndex = 0
                    }
                    playTime += frameTimes[readIndex]
                    realImages.append(values[readIndex])
                    keyTimes.append(NSNumber.init(value: playTime / CMTimeGetSeconds(timeRange.duration)))
                    readIndex += 1
                }
                
                an.keyTimes = keyTimes
                an.values = realImages
                
                gifLayer.add(an, forKey: "gif_an")
            }
        }
        return gifLayer
    }
}
