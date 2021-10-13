//
//  VIdeoEditor.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/9/30.
//

import UIKit
import AVFoundation

/// 视频编辑器
public class VideoEditor: NSObject {
    
    public private(set) var url: URL!
    public private(set) var asset: AVURLAsset!
    public private(set) var preview: UIView!
    
    public convenience init(url: URL, preview: UIView) {
        self.init(asset: AVAsset(url: url), preview: preview)
    }
    
    public init(asset: AVAsset?, preview: UIView) {
        self.preview = preview
        guard asset != nil else {
            return
        }
        if asset is AVURLAsset {
            self.asset = (asset as! AVURLAsset)
        }
    }
    
    
}

extension VideoEditor {
    
}
