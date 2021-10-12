//
//  VIdeoEditor.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/9/30.
//

import UIKit
import AVFoundation

public class VideoEditor: NSObject {
    
    public private(set) var url: URL!
    public private(set) var asset: AVAsset!
    public private(set) var preview: UIView!
    
    public convenience init(url: URL, preview: UIView) {
        self.init(url: url, asset: nil, preview: preview)
    }
    
    public convenience init(asset: AVAsset, preview: UIView) {
        self.init(url: nil, asset: asset, preview: preview)
    }
    
    public init(url: URL?, asset: AVAsset?, preview: UIView) {
        self.url = url
        self.asset = asset
        self.preview = preview
        guard url != nil || asset != nil else {
            return
        }
        
    }
}
