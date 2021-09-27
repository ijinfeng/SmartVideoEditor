//
//  VideoPartsManager.swift
//  VideoPartsManager
//
//  Created by jinfeng on 2021/9/22.
//

import UIKit
import AVFoundation


/// 视频片段管理
public class VideoPartsManager: NSObject {

    // 录制片段写入类
    public class RecordPart: NSObject {
        
        internal var writer: AVAssetWriter?
        
        init(url: URL, fileType: AVFileType = .mp4, videoInput: AVAssetWriterInput, audioInput: AVAssetWriterInput) throws {
            outputURL = url
            do {
                writer = try AVAssetWriter.init(url: url, fileType: fileType)
                if let writer = writer {
                    // https://www.it1352.com/928290.html
                    writer.shouldOptimizeForNetworkUse = true
                    
                    if writer.canAdd(videoInput) {
                        writer.add(videoInput)
                    }
                    if writer.canAdd(audioInput) {
                        writer.add(audioInput)
                    }
                }
            } catch {
                throw VideoRecord.RecordError.initfail(errorMsg: "init AVAssetWriter error: \(error)")
            }
        }
        
        init(url: URL) {
            outputURL = url
        }
        
        public let outputURL: URL!
        
        static func placeholdPart(url: URL) -> RecordPart {
            let part = RecordPart(url: url)
            return part
        }
    }
    
    private var parts: [RecordPart] = []
    
    private var partAutoIncrementKey: Int = 0
    
    public override init() {
        FileHelper.cleanDir(at: VideoRecordConfig.recordPartsDirPath)
    }
    
    private lazy var composition = AVMutableComposition()
}


extension VideoPartsManager {
    public var autoincrementPath: String {
        FileHelper.createDir(at: VideoRecordConfig.defaultRecordOutputDirPath)
        FileHelper.createDir(at: VideoRecordConfig.recordPartsDirPath)
        return VideoRecordConfig.recordPartsDirPath + "\(partAutoIncrementKey).mp4"
    }
}

extension VideoPartsManager {
    
    public func add(part: RecordPart) {
        parts.append(part)
        partAutoIncrementKey += 1
    }
    
    public var currentPart: RecordPart? {
        parts.last
    }
    
    public func deletePart(at index: Int) {
        if index < parts.count {
            let part = parts.remove(at: index)
            FileHelper.removeFile(at: part.outputURL.absoluteString)
        }
    }
    
    public func deleteLastPart() {
        parts.removeLast()
    }
    
    public func deleteAllParts() {
        parts = []
    }
    
    public func insertPart(path: String, at index: Int) {
        let url = URL(fileURLWithPath: path)
        if index < parts.count {
            let part = RecordPart.placeholdPart(url: url)
            parts.insert(part, at: index)
            partAutoIncrementKey += 1
        }
    }
    
    public func mixtureAllParts(outputPath: String) {
        guard parts.count > 0 else {
            return
        }
        
        // 音频轨道
        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        guard let audioTrack = audioTrack else {
            return
        }
        // 视频轨道
        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        guard let videoTrack = videoTrack else {
            return
        }
        
        var totalDuration = CMTime.zero
        
        for part in parts {
            let asset = AVURLAsset(url: part.outputURL)
            if let assetAuditoTrack = asset.tracks(withMediaType: .audio).first {
                audioTrack.insertTimeRange(CMTimeRange.init(start: CMTime.zero, end: asset.duration), of: assetAuditoTrack, at: totalDuration)
            }
            if let assetVideoTrack = asset.tracks(withMediaType: .video).first {
                videoTrack.insertTimeRange(CMTimeRange.init(start: CMTime.zero, end: asset.duration), of: assetVideoTrack, at: totalDuration)
            }
            totalDuration = CMTimeAdd(totalDuration, asset.duration)
        }
        
        let outputURL = URL(fileURLWithPath: outputPath)
        if !FileManager.default.fileExists(atPath: outputPath) {
            print("开始导入")
            print(outputURL)
        }
    }
}
