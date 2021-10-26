//
//  TransitionComposition.swift
//  VideoTransition
//
//  Created by jinfeng on 2021/10/25.
//

import UIKit
import AVFoundation

/// 转场组合
public class TransitionComposition: NSObject {
    private var composition: AVMutableComposition!
    private var videoComposition: AVMutableVideoComposition!
    private var audioMix: AVMutableAudioMix!
    private var items: [TransitionItem] = []
    private var resources: [TransitionResource] = []
    
    public fileprivate(set) var assets: [AVAsset] = []
    
    /// 画布大小，实际渲染的视频的画面尺寸由`contentMode`决定和视频本身的`naturalSize`决定
    public var renderSize: CGSize = {
        let screen = UIScreen.main.bounds
        return CGSize(width: screen.width * 2, height: screen.height * 2)
    }()
    
    struct TransitionResource {
        var asset: AVAsset
        var timeRange: CMTimeRange
    }
    
    public enum VideoContentMode: Int {
        /// 填充满，会拉伸
        case fill = 0
        /// 以裁剪的方式填充，不拉伸
        case fillToScale = 1
        /// 以最长宽或最长高适配屏幕，不拉伸
        case fitToScale = 2
    }
    public var contentMode: VideoContentMode = .fitToScale
}

// MARK: Public API
extension TransitionComposition {
    public func add(asset: AVAsset, timeRange: CMTimeRange, completionHanlder handler: ((TransitionItem) -> Void)? = nil) {
        guard !timeRange.isEmpty else {
            return
        }
        
        let resource = TransitionResource(asset: asset, timeRange: timeRange)
        resources.append(resource)
        
        self.assets.append(asset)
        guard self.assets.count > 1 else {
            return
        }

        let total = self.assets.count
        let index = total - 1
        let from = self.assets[index - 1]
        let to = self.assets[index]
        
        let item = TransitionItem.init(asset: from, to: to)
        items.append(item)
        handler?(item)
    }
    
    public func buildTransitionComposition() {
        composition = AVMutableComposition()
        videoComposition = AVMutableVideoComposition()
        audioMix = AVMutableAudioMix()
        
        var videoTracks: [AVMutableCompositionTrack] = []
        var audioTracks: [AVMutableCompositionTrack] = []
        
        var passThroughTimeRanges: [CMTimeRange] = []
        var transitionTimeRanges: [CMTimeRange] = []
        
        if let track = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) {
            videoTracks.append(track)
        }
        if let track = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) {
            videoTracks.append(track)
        }
        if let track = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            audioTracks.append(track)
        }
        if let track = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            audioTracks.append(track)
        }
        
        var nextClipStartTime: CMTime = .zero
        let clipsCount = resources.count
            
        for i in 0..<clipsCount {
            let trackIndex = i % 2
            let resorce = resources[i]
            var item: TransitionItem? = nil
            if i > 0 {
                item = items[i - 1]
            }

            if let item = item {
                passThroughTimeRanges[i - 1].duration = CMTimeSubtract(passThroughTimeRanges[i - 1].duration, item.intersectionTime)
                nextClipStartTime = CMTimeSubtract(nextClipStartTime, item.intersectionTime)
                
                transitionTimeRanges.append(CMTimeRangeMake(start: nextClipStartTime, duration: item.intersectionTime))
            }
            
            if let video = resorce.asset.tracks(withMediaType: .video).first {
                try? videoTracks[trackIndex].insertTimeRange(resorce.timeRange, of: video, at: nextClipStartTime)
            }
            if let audio = resorce.asset.tracks(withMediaType: .audio).first {
                try? audioTracks[trackIndex].insertTimeRange(resorce.timeRange, of: audio, at: nextClipStartTime)
            }
            
            let range = CMTimeRangeMake(start: nextClipStartTime, duration: resorce.timeRange.duration)
            passThroughTimeRanges.append(range)
            if let item = item {
                passThroughTimeRanges[i].start = CMTimeAdd(passThroughTimeRanges[i].start, item.intersectionTime)
                passThroughTimeRanges[i].duration = CMTimeSubtract(passThroughTimeRanges[i].duration, item.intersectionTime)
            }
            
            nextClipStartTime = CMTimeAdd(nextClipStartTime, resorce.timeRange.duration)
        }
        
        var instructions: [AVVideoCompositionInstruction] = []
        var trackMixArray: [AVMutableAudioMixInputParameters] = []
        
        let audioMix1 = AVMutableAudioMixInputParameters.init(track: audioTracks[0])
        let audioMix2 = AVMutableAudioMixInputParameters.init(track: audioTracks[1])
        trackMixArray = [audioMix1, audioMix2]
        
        for i in 0..<clipsCount {
            let trackIndex = i % 2

            let passThroughInstruction = AVMutableVideoCompositionInstruction()
            passThroughInstruction.timeRange = passThroughTimeRanges[i]

            let passThroughLayer = AVMutableVideoCompositionLayerInstruction.init(assetTrack: videoTracks[trackIndex])
            resizeInstructionLayer(passThroughLayer, resources[i].asset)
            passThroughInstruction.layerInstructions = [passThroughLayer]
            instructions.append(passThroughInstruction)

            if i + 1 < clipsCount {
                var type: TransitionItem.Transition = .dissolve
                if i < items.count {
                    type = items[i].type
                }
                let transitionInstruction = AVMutableVideoCompositionInstruction()
                transitionInstruction.timeRange = transitionTimeRanges[i]

                let fromLayer = AVMutableVideoCompositionLayerInstruction.init(assetTrack: videoTracks[trackIndex])
                let fromt = resizeInstructionLayer(fromLayer, resources[i].asset)
                let toLayer = AVMutableVideoCompositionLayerInstruction.init(assetTrack: videoTracks[1 - trackIndex])
                let tot = resizeInstructionLayer(toLayer, resources[i + 1].asset)
                
                switch type {
                case .dissolve:
                    fromLayer.setOpacityRamp(fromStartOpacity: 1, toEndOpacity: 0, timeRange: transitionTimeRanges[i])
                    toLayer.setOpacityRamp(fromStartOpacity: 0, toEndOpacity: 1, timeRange: transitionTimeRanges[i])
                case .push:
                    // 这里不一定是width，因为有可能视频经过放大，所以需要乘上缩放比
                    let froms = getTransformScale(resources[i].asset)
                    let tos = getTransformScale(resources[i + 1].asset)
                    let from = fromt.translatedBy(x: -renderSize.width / froms.ws, y: 0)
                    let to = tot.translatedBy(x: renderSize.width / tos.ws, y: 0)

                    fromLayer.setTransformRamp(fromStart: fromt, toEnd: from, timeRange: transitionTimeRanges[i])
                    toLayer.setTransformRamp(fromStart: to, toEnd: tot, timeRange: transitionTimeRanges[i])
                case .wipe:
                    let size = renderSize
                    let start = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                    let end = CGRect(x: 0, y: size.height, width: size.width, height: 0)
                    fromLayer.setCropRectangleRamp(fromStartCropRectangle: start, toEndCropRectangle: end, timeRange: transitionTimeRanges[i])
                }
                
                transitionInstruction.layerInstructions = [fromLayer, toLayer]
                instructions.append(transitionInstruction)
            }
            
            trackMixArray[trackIndex].setVolumeRamp(fromStartVolume: 1, toEndVolume: 1, timeRange: passThroughTimeRanges[i])
            if i < transitionTimeRanges.count {
                trackMixArray[trackIndex].setVolumeRamp(fromStartVolume: 1, toEndVolume: 0, timeRange: transitionTimeRanges[i])
                trackMixArray[1 - trackIndex].setVolumeRamp(fromStartVolume: 0, toEndVolume: 1, timeRange: transitionTimeRanges[i])
            }
        }
        
        audioMix.inputParameters = trackMixArray
        videoComposition.instructions = instructions
        videoComposition.frameDuration = CMTime.init(value: 1, timescale: 30)
        videoComposition.renderSize = renderSize
        videoComposition.renderScale = 1.0
    }
    
    public func getPlayerItem() -> AVPlayerItem {
        let playItem = AVPlayerItem(asset: composition)
        playItem.videoComposition = videoComposition
        playItem.audioMix = audioMix
        return playItem
    }
    
    public func getComposition() -> AVMutableComposition {
        composition
    }
    
    public func getVideoComposition() -> AVMutableVideoComposition {
        videoComposition
    }
    
    public func getAudioMix() -> AVMutableAudioMix {
        audioMix
    }
}

// MARK: Private API
extension TransitionComposition {
    
    /// 设置`LayerInstruction`的形变信息
    /// - Parameters:
    ///   - layer: AVMutableVideoCompositionLayerInstruction
    ///   - asset: 视频资源
    /// - Returns: 变化后的矩阵对象
    @discardableResult private func resizeInstructionLayer(_ layer: AVMutableVideoCompositionLayerInstruction, _ asset: AVAsset) -> CGAffineTransform {
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            return .identity
        }
        // 视频原始尺寸大小
        let naturalSize = videoTrack.naturalSize
        var t = videoTrack.preferredTransform
        switch contentMode {
        case .fill:
            let ws = renderSize.width / naturalSize.width
            let hs = renderSize.height / naturalSize.height
            t = t.scaledBy(x: ws, y: hs)
        case .fillToScale:
            let naturalScale = naturalSize.width / naturalSize.height
            let renderScale = renderSize.width / renderSize.height
            
            if naturalScale > renderScale {
                // 定高，宽放大
                let renderWidth = renderSize.height / naturalSize.height * naturalSize.width
                t = t.translatedBy(x: (renderSize.width - renderWidth) / 2, y: 0)
                let hs = renderSize.height / naturalSize.height
                t = t.scaledBy(x: hs, y: hs)
            } else {
                let renderHeight = renderSize.width / naturalSize.width * naturalSize.height
                t = t.translatedBy(x: 0, y: (renderSize.height - renderHeight) / 2)
                let ws = renderSize.width / naturalSize.width
                t = t.scaledBy(x: ws, y: ws)
            }
        case .fitToScale:
            let naturalScale = naturalSize.width / naturalSize.height
            let renderScale = renderSize.width / renderSize.height
            if naturalScale > renderScale {
                // 以视频的宽固定值，缩放高
                let renderHeight = renderSize.width / naturalSize.width * naturalSize.height
                t = t.translatedBy(x: 0, y: (renderSize.height - renderHeight) / 2)
                let ws = renderSize.width / naturalSize.width
                t = t.scaledBy(x: ws, y: ws)
            } else {
                let renderWidth = renderSize.height / naturalSize.height * naturalSize.width
                t = t.translatedBy(x: (renderSize.width - renderWidth) / 2, y: 0)
                let hs = renderSize.height / naturalSize.height
                t = t.scaledBy(x: hs, y: hs)
            }
        }
        layer.setTransform(t, at: .zero)
        return t
    }
    
    /// 获取视频资源需要的缩放比例
    /// - Parameter asset: 视频资源
    /// - Returns: `ws`: 宽的缩放比，`hs`: 高的缩放比
    private func getTransformScale(_ asset: AVAsset) -> (ws: CGFloat, hs: CGFloat) {
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            return (1, 1)
        }
        // 视频原始尺寸大小
        let naturalSize = videoTrack.naturalSize
        switch contentMode {
        case .fill:
            let ws = renderSize.width / naturalSize.width
            let hs = renderSize.height / naturalSize.height
            return (ws, hs)
        case .fillToScale:
            let naturalScale = naturalSize.width / naturalSize.height
            let renderScale = renderSize.width / renderSize.height
            if naturalScale > renderScale {
                let hs = renderSize.height / naturalSize.height
                return (hs, hs)
            } else {
                let ws = renderSize.width / naturalSize.width
                return (ws, ws)
            }
        case .fitToScale:
            let naturalScale = naturalSize.width / naturalSize.height
            let renderScale = renderSize.width / renderSize.height
            if naturalScale > renderScale {
                let ws = renderSize.width / naturalSize.width
                return (ws, ws)
            } else {
                let hs = renderSize.height / naturalSize.height
                return (hs, hs)
            }
        }
    }
}
