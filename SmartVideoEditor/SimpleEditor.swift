//
//  SimpleEditor.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/10/20.
//

import UIKit
import AVFoundation
import VideoEditor

class SimpleEditor: NSObject {
    var clips: [AVURLAsset] = []
    var clipTimeRanges: [CMTimeRange] = []
    var transitionDuration: CMTime = CMTimeMakeWithSeconds(1, preferredTimescale: 1)
    var composition: AVMutableComposition!
    var videoComposition: AVMutableVideoComposition!
    var audioMix: AVMutableAudioMix!
    
}

extension SimpleEditor {
    func buildCompositionObjectsForPlayback() {
        guard clips.count > 0 else {
            return
        }
        var videoSize = CGSize.zero
        
        for clip in clips {
            print("angle= \(clip.preferredTransform.getTransformAngle())")
            for track in clip.tracks(withMediaType: .video) {
                print("track size= \(track.naturalSize)")
            }
        }
        
        
//        videoSize = CGSize.init(width: 1080, height: 1920)
        // 注意这个值，有些不能显示画面
        videoSize = CGSize(width: 640 , height: 370 )
        
        let composition = AVMutableComposition()
        let videoComposition = AVMutableVideoComposition()
        let audioMix = AVMutableAudioMix()
        
        composition.naturalSize = videoSize
        
        var nextClipStartTime: CMTime = .zero
        let clipsCount = clips.count
        
        var transitionDuration = self.transitionDuration
        for i in 0..<clipsCount {
            let range = clipTimeRanges[i]
            var halfClipDuration = range.duration
            halfClipDuration.timescale *= 2
            transitionDuration = CMTimeMinimum(transitionDuration, halfClipDuration)
        }
        // 创建多轨视频
        let mutVideoTrack1 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let mutVideoTrack2 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let mutAudioTrack1 = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        let mutAudioTrack2 = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let compositionVideoTracks = [mutVideoTrack1, mutVideoTrack2]
        let compositionAudioTracks = [mutAudioTrack1, mutAudioTrack2]
        
        /// AVMutableComposition { videoTrack1, videoTrack2 }
        /// videoTrack1:  ｜ video1 ｜ empty ｜ video3 ｜
        /// videoTrack2:  | empty   | video2 | empty  |
        
        // 通过的时间范围
        var passThroughTimeRanges: [CMTimeRange] = []
        // 过度的时间范围
        var transitionTimeRanges: [CMTimeRange] = []
        
        var totalTime: CMTime = .zero
            
        for i in 0..<clipsCount {
            let index = i % 2
            let asset = clips[i]
            let clipTimeRange = clipTimeRanges[i]

            let timeRangeInAsset = clipTimeRange

            print("===========timeRangeInAsset")
            print("assetRange=    \(CMTimeRangeShow(timeRangeInAsset))")

            let videoTrack = asset.tracks(withMediaType: .video)[0]
            try? compositionVideoTracks[index]?.insertTimeRange(timeRangeInAsset, of: videoTrack, at: nextClipStartTime)

            let audioTrack = asset.tracks(withMediaType: .audio)[0]
            try? compositionAudioTracks[index]?.insertTimeRange(timeRangeInAsset, of: audioTrack, at: nextClipStartTime)

            print("==========TrackTimeRange")
            print("track=      \(CMTimeRangeShow(compositionVideoTracks[index]!.timeRange))")
            

            print("===========transitionDuration")
            print("transition=    \(CMTimeShow(transitionDuration))")

            
            totalTime = CMTimeAdd(totalTime, timeRangeInAsset.duration)
            // 注意叠加区域别算错了，否则将会出现黑屏无法播放

            // 除去头和尾部的片段，中间的视频片段都是有两个重叠部分，因此要减两次 `transitionDur`
            var range = CMTimeRangeMake(start: nextClipStartTime, duration: timeRangeInAsset.duration)
            if i > 0 {
                range.start = CMTimeAdd(range.start, transitionDuration)
                range.duration = CMTimeSubtract(range.duration, transitionDuration)
            }
            if i + 1 < clipsCount {
                range.duration = CMTimeSubtract(range.duration, transitionDuration)
            }

            passThroughTimeRanges.append(range)

            nextClipStartTime = CMTimeAdd(nextClipStartTime, timeRangeInAsset.duration)
            nextClipStartTime = CMTimeSubtract(nextClipStartTime, transitionDuration)

            print("============nextClipStartTime")
            print("next=    \(CMTimeShow(nextClipStartTime))")

            print("=========passThroughTimeRanges")
            print("pass=     \(CMTimeRangeShow(range))")

            if i + 1 < clipsCount {
                let range = CMTimeRangeMake(start: nextClipStartTime, duration: transitionDuration)
                transitionTimeRanges.append(range)

                print("=========transitionTimeRanges")
                print("tran=     \(CMTimeRangeShow(range))")
            }

        }

        
        print("=========passThroughTimeRanges")
        for range in passThroughTimeRanges {
            print("pass=     \(CMTimeRangeShow(range))")
        }
        print("=========transitionTimeRanges")
        for range in transitionTimeRanges {
            print("pass=     \(CMTimeRangeShow(range))")
        }
        
        print("\n\n\n")
        
        /*
         =========passThroughTimeRanges
         {{0/1 = 0.000}, {4765/600 = 7.942}}
         pass=     ()
         {{4765/600 = 7.942}, {4798/600 = 7.997}}
         pass=     ()
         =========transitionTimeRanges
         {{3565/600 = 5.942}, {1200/600 = 2.000}}
         tran=     ()

         */
        
        // MARK: Instruction
        
        var instructions: [AVVideoCompositionInstruction] = []
        var trackMixArray: [AVMutableAudioMixInputParameters] = []
        
        
        for i in 0..<clipsCount {
            let index = i % 2

            let passThroughInstruction = AVMutableVideoCompositionInstruction()
            passThroughInstruction.timeRange = passThroughTimeRanges[i]

            let passThroughLayer = AVMutableVideoCompositionLayerInstruction.init(assetTrack: compositionVideoTracks[index]!)
            passThroughLayer.setTransform(compositionVideoTracks[index]!.preferredTransform, at: .zero)
            passThroughInstruction.layerInstructions = [passThroughLayer]

            instructions.append(passThroughInstruction)

            if i + 1 < clipsCount {
                let transitionInstruction = AVMutableVideoCompositionInstruction()
                transitionInstruction.timeRange = transitionTimeRanges[i]

                let fromLayer = AVMutableVideoCompositionLayerInstruction.init(assetTrack: compositionVideoTracks[index]!)
                fromLayer.setOpacityRamp(fromStartOpacity: 1, toEndOpacity: 0, timeRange: transitionTimeRanges[i])
                let toLayer = AVMutableVideoCompositionLayerInstruction.init(assetTrack: compositionVideoTracks[1 - index]!)
                toLayer.setOpacityRamp(fromStartOpacity: 0, toEndOpacity: 1, timeRange: transitionTimeRanges[i])
                transitionInstruction.layerInstructions = [fromLayer, toLayer]

                instructions.append(transitionInstruction)


                let trackMix1 = AVMutableAudioMixInputParameters.init(track: compositionAudioTracks[0])
                trackMix1.setVolumeRamp(fromStartVolume: 1, toEndVolume: 0, timeRange: transitionTimeRanges[0])
                trackMixArray.append(trackMix1)

                let trackMix2 = AVMutableAudioMixInputParameters.init(track: compositionAudioTracks[1])
                trackMix2.setVolumeRamp(fromStartVolume: 0, toEndVolume: 1, timeRange: transitionTimeRanges[0])
                trackMix2.setVolumeRamp(fromStartVolume: 1, toEndVolume: 0, timeRange: passThroughTimeRanges[1])
                trackMixArray.append(trackMix2)
            }
        }
        
        audioMix.inputParameters = trackMixArray
        videoComposition.instructions = instructions
        videoComposition.frameDuration = CMTime.init(value: 1, timescale: 30)
        videoComposition.renderSize = videoSize
        videoComposition.renderScale = 1.0
        
        self.videoComposition = videoComposition
        self.composition = composition
        self.audioMix = audioMix
    }
    
    func getPlayerItem() -> AVPlayerItem {
        let item = AVPlayerItem(asset: composition)
        item.videoComposition = videoComposition
        item.audioMix = audioMix
        return item
    }
}


