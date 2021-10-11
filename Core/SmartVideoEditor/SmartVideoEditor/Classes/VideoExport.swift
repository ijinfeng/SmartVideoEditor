//
//  VideoExport.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/9/28.
//

import UIKit
import AVFoundation

/// 视频导出
class VideoExport: NSObject {
    private static let shared = VideoExport()
    private let exportQueue = DispatchQueue.init(label: "ijf_export_queue", qos: .default, attributes: .concurrent)
    private let semaphore = DispatchSemaphore.init(value: 1)
    
    static func exportVideo(assetURL: URL?,
                            asset: AVAsset?,
                            outputURL: URL,
                            ouputFileType: AVFileType = .mp4,
                            presetName: String = AVAssetExportPreset1280x720,
                            filter: VideoFilter? = nil,
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
            VideoExport.shared.exportQueue.async {
                export.exportAsynchronously {
                    print("export asyn")
                    DispatchQueue.main.async {
                        print("export finished with status is: \(export.status)")
                        switch export.status {
                        case .completed:
                            complication(true)
                        default:
                            complication(false)
                        }
                    }
                }
            }
        }
    }
}


extension String {
    public var fileURL: URL {
        URL(fileURLWithPath: self)
    }
}
