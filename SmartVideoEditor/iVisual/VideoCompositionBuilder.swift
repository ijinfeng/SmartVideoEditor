//
//  VideoCompositionBuilder.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/11/9.
//

import Foundation
import AVFoundation

public class VideoCompositionBuilder {
    private var outVideoComposition: AVVideoComposition?
    
    public init(exist videoComposition: AVVideoComposition?) {
        outVideoComposition = videoComposition
    }
    
}

// MARK: Public API
public extension VideoCompositionBuilder {
    func buildVideoCompositon(with timeLine: TimeLine) -> AVVideoComposition {
        let c = CompositionCoordinator(timeLine: timeLine)
        CompositionCoordinatorPool.shared.add(coordinator: c)
        
        let videoComposition = (outVideoComposition?.mutableCopy() as? AVMutableVideoComposition) ?? AVMutableVideoComposition(propertiesOf: timeLine.asset)
        videoComposition.renderSize = timeLine.renderSize
        videoComposition.renderScale = timeLine.renderScale
        videoComposition.frameDuration = timeLine.frameDuration
        videoComposition.customVideoCompositorClass = VideoCustomComposition.self
        
        return videoComposition
    }
}
