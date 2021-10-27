//
//  ImageOverlap.swift
//  VideoVisualEffects
//
//  Created by jinfeng on 2021/10/27.
//

import UIKit

public class ImageOverlap: VideoOverlap {
    public private(set) var image: UIImage!
    private var rect: CGRect!
    
    public init(image: UIImage, rect: CGRect) {
        self.image = image
        self.rect = rect
    }
    
    public override func rectOfContent() -> CGRect {
        rect
    }
    
    public override func layerOfContent() -> CALayer {
        let imageLayer = CALayer()
        imageLayer.contents = image.cgImage
        return imageLayer
    }
}
