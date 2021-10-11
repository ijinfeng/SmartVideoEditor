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
    private var filters: [CIFilter] = []
    
    internal func apply(to image: CIImage) -> CIImage {
        if filters.isEmpty {
            return image
        }
        var filterOutputImage: CIImage?
        for filter in filters {
            if let outputImage = filterOutputImage {
                filter.setValue(outputImage, forKey: kCIInputImageKey)
            } else {
                filter.setValue(image, forKey: kCIInputImageKey)
            }
            filterOutputImage = filter.outputImage ?? image
        }
        return filterOutputImage ?? image
    }
    
    private func createFilter(name: Name) -> CIFilter? {
        var _filter: CIFilter?
        switch name {
        case let .custom(customName, attribute):
            if let filter = CIFilter.init(name: customName) {
                if let keyedValues = attribute {
                    filter.setValuesForKeys(keyedValues)
                }
                _filter = filter
            }
        default:
            _filter = CIFilter.init(name: name.rawValue)
        }
        return _filter
    }
}

// MARK: public
extension VideoFilter {
    @discardableResult
    public func setFilter(name: Name) -> VideoFilter {
        guard self.name != name else {
            return self
        }
        self.name = name
        if let filter = createFilter(name: name) {
            filters = [filter]
        } else {
            filters = []
        }
        return self
    }
    
    @discardableResult
    public func appendFilter(name: Name) -> VideoFilter {
        if let filter = createFilter(name: name) {
            filters.append(filter)
        }
        return self
    }
}

extension VideoFilter {
    public enum Name {
        /// 不添加滤镜
        case none
        /// 反色
        case invert
        /// 单色
        case single
        /// 怀旧、复古
        case ancient
        /// 岁月
        case years
        /// 灰白
        case noir
        /// 自定义
        case custom(String, [String: Any]? = nil)
    }
}

extension VideoFilter.Name: RawRepresentable {
    public init?(rawValue: String) {
        return nil
    }
    
    public typealias RawValue = String
    
    public var rawValue: RawValue {
        switch self {
        case .invert:
            return "CIColorInvert"
        case .single:
            return "CIPhotoEffectMono"
        case .ancient:
            return "CIPhotoEffectInstant"
        case .years:
            return "CIPhotoEffectTransfer"
        case .noir:
            return "CIPhotoEffectNoir"
        case .custom(_, _):
            return "custom"
        default:
            return ""
        }
    }
}
