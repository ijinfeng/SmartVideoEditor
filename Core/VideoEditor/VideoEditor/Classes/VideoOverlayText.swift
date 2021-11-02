//
//  TextOverlay.swift
//  VideoVisualEffects
//
//  Created by jinfeng on 2021/10/27.
//

import UIKit

public class VideoOverlayText: VideoOverlay {
    public private(set) var text: NSAttributedString!
    private var rect: CGRect!
    
    public init(text: NSAttributedString, rect: CGRect) {
        self.text = text
        self.rect = rect
    }
    
    public override func rectOfContent() -> CGRect {
        rect
    }
    
    public override func layerOfContent() -> CALayer {
        let textLayer = CATextLayer()
        textLayer.string = text
        textLayer.isHidden = true
        return textLayer
    }
}
