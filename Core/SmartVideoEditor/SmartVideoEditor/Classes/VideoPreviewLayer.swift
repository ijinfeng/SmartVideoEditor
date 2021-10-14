//
//  VideoPlayerLayer.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/9/29.
//

import Foundation
import QuartzCore


protocol VideoPreviewViewDelegate: AnyObject {
    func didTouch(at point: CGPoint)
    func didPinching(scale: CGFloat, velocity: CGFloat)
}

class VideoPreviewView: UIView {
    
    internal var enablePinch: Bool = true {
        didSet {
            pinch.isEnabled = enablePinch
        }
    }
    
    internal weak var delegate: VideoPreviewViewDelegate?
    
    private lazy var pinch = UIPinchGestureRecognizer.init(target: self, action: #selector(onPinchProgress(_:)))
    
    private let focusImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor(red: 1.0, green: 180/255.0, blue: 0, alpha: 1.0).cgColor
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(focusImageView)
        addGestureRecognizer(pinch)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override class var layerClass: AnyClass {
        VideoPreviewLayer.self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: self)
            delegate?.didTouch(at: point)
            gradualShowFocusImage(in: point)
        }
    }
}

extension VideoPreviewView {
    internal func setCustomFocusImage(_ image: UIImage?) {
        focusImageView.image = image
        if let _ = image {
            focusImageView.layer.borderWidth = 0
        } else {
            focusImageView.layer.borderWidth = 1
        }
    }
    
    internal func gradualShowFocusImage(in center: CGPoint) {
        var size = CGSize(width: 100, height: 100)
        if let image = focusImageView.image {
            size = image.size
        }
        focusImageView.frame = CGRect(origin: .zero, size: size)
        focusImageView.center = center
        focusImageView.transform = .init(scaleX: 1.2, y: 1.2)
        focusImageView.alpha = 1.0
        UIView.animate(withDuration: 0.3) {
            self.focusImageView.transform = .init(scaleX: 1.0, y: 1.0)
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                self.focusImageView.alpha = 0
            }
        }
    }
}

// MARK: Actions
extension VideoPreviewView {
    @objc func onPinchProgress(_ gr: UIPinchGestureRecognizer) {
        delegate?.didPinching(scale: gr.scale, velocity: gr.velocity)
    }
}

class VideoPreviewLayer: CALayer {
    
}
