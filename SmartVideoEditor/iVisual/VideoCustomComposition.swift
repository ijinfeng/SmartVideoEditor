//
//  VideoCustomComposition.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/11/8.
//

import UIKit
import AVFoundation

public class VideoCustomComposition: NSObject, AVVideoCompositing {
    private var shouldCancelAllPendingRequests = false
    private let renderQueue = DispatchQueue.init(label: "com.ijinfeng.customComposition.renderQueue")
    private var renderContext: AVVideoCompositionRenderContext?
    
    public static var ciContext: CIContext = CIContext()
    
    private let coordinator: CompositionCoordinator? = CompositionCoordinatorPool.shared.pop()
    
    public enum VideoCustomCompositionError: Error {
        case newPixelBufferRequestFailed
    }
    
    public var sourcePixelBufferAttributes: [String : Any]? = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                                                        String(kCVPixelBufferOpenGLESCompatibilityKey): true]
    
    public var requiredPixelBufferAttributesForRenderContext: [String : Any] = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                                                                         String(kCVPixelBufferOpenGLESCompatibilityKey): true]
    
    public func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        renderQueue.sync { [weak self] in
            self?.renderContext = newRenderContext
        }
    }
    
    public func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        renderQueue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            if strongSelf.shouldCancelAllPendingRequests {
                asyncVideoCompositionRequest.finishCancelledRequest()
            } else {
                autoreleasepool {
                    if let pixelBuffer = strongSelf.handleNewPixelBuffer(from: asyncVideoCompositionRequest) {
                        asyncVideoCompositionRequest.finish(withComposedVideoFrame: pixelBuffer)
                    } else {
                        asyncVideoCompositionRequest.finish(with: VideoCustomCompositionError.newPixelBufferRequestFailed)
                    }
                }
            }
        }
    }
    
    public func cancelAllPendingVideoCompositionRequests() {
        shouldCancelAllPendingRequests = true
        renderQueue.async(flags: .barrier) { [weak self] in
            self?.shouldCancelAllPendingRequests = false
        }
    }
}

// MARK: Private API
private extension VideoCustomComposition {
    func handleNewPixelBuffer(from request: AVAsynchronousVideoCompositionRequest) -> CVPixelBuffer? {
        // ???????????????????????????
        guard let pixelBuffer = request.renderContext.newPixelBuffer() else {
            return nil
        }
    
        // ?????????????????? VideoComposition ??? renderSize
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        var image: CIImage?
        
        var backgroundColor: CGColor = UIColor.black.cgColor
        if let instruction =  request.videoCompositionInstruction as? AVVideoCompositionInstruction {
            backgroundColor = instruction.backgroundColor ?? UIColor.black.cgColor
        }
        if let coordinator = coordinator {
            if let timeLineBackgroundColor = coordinator.timeLine.backgroundColor {
                backgroundColor = timeLineBackgroundColor.cgColor
            }
        }
        
        // ???????????????
        let backgroundImage = CIImage(color: CIColor(cgColor: backgroundColor)).cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
        
        // ????????????????????????
        for trackID in request.sourceTrackIDs {
            if let sourcePixelBuffer = request.sourceFrame(byTrackID: trackID.int32Value) {
                let sourceImage = CIImage(cvPixelBuffer: sourcePixelBuffer)
                image = sourceImage
            }
        }
        
        // ??????????????????????????????????????????????????????
        guard var videoImage = image else {
            VideoCustomComposition.ciContext.render(backgroundImage, to: pixelBuffer)
            return pixelBuffer
        }
        
        // ????????????????????????
        if let coordinator = coordinator {
            videoImage = coordinator.apply(source: videoImage, at: request.compositionTime)
        }
        
        videoImage = videoImage.composited(over: backgroundImage)
        
        // ???????????????????????????????????????
        VideoCustomComposition.ciContext.render(videoImage, to: pixelBuffer)
        
        return pixelBuffer
    }
}
