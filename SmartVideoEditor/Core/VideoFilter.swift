//
//  VideoFilter.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/9/29.
//

import UIKit

// https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html#//apple_ref/doc/uid/TP30000136-SW29

public class VideoFilter: NSObject {
    
    public private(set) var name: Name = .none
    private var filter: CIFilter?
    
    func apply(to image: CIImage) -> CIImage {
        if let filter = filter {
            filter.setValue(image, forKey: kCIInputImageKey)
            return filter.outputImage ?? image
        } else {
            return image
        }
    }
    
    func setFilter(name: Name) {
        guard self.name != name else {
            return
        }
        self.name = name
        filter = CIFilter.init(name: name.rawValue)
    }
}

extension VideoFilter {
    public enum Name: String {
        /// 不添加滤镜
        case none
        /// 反色
        case invert = "CIColorInvert"
        /// 单色
        case single = "CIPhotoEffectMono"
        /// 怀旧、复古
        case ancient = "CIPhotoEffectInstant"
        /// 岁月
        case years = "CIPhotoEffectTransfer"
        /// 灰白
        case noir = "CIPhotoEffectNoir"
    }
}
