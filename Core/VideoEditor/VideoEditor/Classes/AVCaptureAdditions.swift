//
//  AVCaptureAdditions.swift
//  VideoEditor
//
//  Created by jinfeng on 2021/10/19.
//

import UIKit
import AVFoundation

extension AVCaptureDevice {
    
    /// 是否支持高帧率捕捉
    public func isSupportsHighFrameRateCapture() -> Bool {
        
        if !hasMediaType(.video) {
            return false
        }
        
        var maxFrameRateRange: AVFrameRateRange?
        
        for format in self.formats {
            let ranges = format.videoSupportedFrameRateRanges
            for range in ranges {
                if maxFrameRateRange != nil {
                    if range.maxFrameRate > maxFrameRateRange!.maxFrameRate {
                        maxFrameRateRange = range
                    }
                }
                else {
                    maxFrameRateRange = range
                }
            }
        }
        
        if let maxFrameRateRange = maxFrameRateRange {
            return maxFrameRateRange.maxFrameRate > 30
        }
        
        return false
    }
    
    
    /// 设置最大可支持的帧率
    /// - Returns: 帧率
    public func maxSupportFrameRate() -> Float64 {
        if !hasMediaType(.video) {
            return 30
        }
        
        var maxFrameRateRange: AVFrameRateRange?
        
        for format in self.formats {
            let ranges = format.videoSupportedFrameRateRanges
            for range in ranges {
                if maxFrameRateRange != nil {
                    if range.maxFrameRate > maxFrameRateRange!.maxFrameRate {
                        maxFrameRateRange = range
                    }
                }
                else {
                    maxFrameRateRange = range
                }
            }
        }
        
        if let maxFrameRateRange = maxFrameRateRange {
            return maxFrameRateRange.maxFrameRate
        }
        
        return 30
    }
}
