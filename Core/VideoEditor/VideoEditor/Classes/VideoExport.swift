//
//  VideoExport.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/9/28.
//

import UIKit
import AVFoundation

/// 视频导出
public class VideoExport: NSObject {
    private static let shared = VideoExport()
    private let exportQueue = DispatchQueue.init(label: "ijf_export_queue", qos: .default, attributes: .concurrent)
    
    public static func exportVideo(assetURL: URL?,
                            asset: AVAsset?,
                            outputURL: URL,
                            ouputFileType: AVFileType = .mp4,
                            presetName: String = AVAssetExportPreset1280x720,
                            filter: VideoFilter? = nil,
                            videoComposition: AVVideoComposition? = nil,
                            audioMix: AVAudioMix? = nil,
                            complication: @escaping (Bool) -> Void) throws {
        guard FileHelper.fileExists(at: outputURL.absoluteString) == false else {
            throw VideoSessionError.Export.fileExists
        }
        
        var uasset = asset
        
        if uasset == nil {
            guard let uassetURL = assetURL else {
                throw VideoSessionError.Export.assetEmpty
            }
            uasset = AVAsset(url: uassetURL)
        }
        guard let _asset = uasset else {
            throw VideoSessionError.Export.assetEmpty
        }
        
        var preset = presetName
        if !AVAssetExportSession.allExportPresets().contains(preset) {
            preset = AVAssetExportPresetMediumQuality
        }
        
        if let export = AVAssetExportSession(asset: _asset, presetName: preset) {
            export.outputFileType = ouputFileType
            export.outputURL = outputURL
            export.shouldOptimizeForNetworkUse = true
            if let filter = filter {
                let videoComposition = AVVideoComposition(asset: _asset) { request in
                    let outputImage = filter.apply(to: request.sourceImage)
                    request.finish(with: outputImage, context: nil)
                }
                export.videoComposition = videoComposition
            }
            // 这里如何处理filter 和 videoComposition的关系
            if let videoComposition = videoComposition {
                export.videoComposition = videoComposition
            }
            if let audioMix = audioMix {
                export.audioMix = audioMix
            }
            VideoExport.shared.exportQueue.async {
                export.exportAsynchronously {
                    print("export asyn")
                    DispatchQueue.main.async {
                        print("export finished with status is: \(export.status.rawValue), error: \(export.error?.localizedDescription ?? "noError")")
                        switch export.status {
                        case .completed:
                            complication(true)
                        default:
#if DEBUG
                            if export.error != nil {
                                print("====> export error detail:\n\t \(export.error!)")
                            }
#endif
                            complication(false)
                        }
                    }
                }
            }
        }
    }
}
