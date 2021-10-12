//
//  VideoInfoReader.swift
//  VideoEditor
//
//  Created by jinfeng on 2021/10/12.
//

import UIKit
import AVFoundation

public class VideoInfo: NSObject {
    
    /// 封面图
    public var coverImage: UIImage?
    
    public var filePath: String = ""
    
    /// 时长
    public var duration: TimeInterval = 0
    
    /// 帧率
    public var fps: Float = 0
    
    /// 大小
    public var fileSize: UInt64 = 0
    
    /// 比特率
    public var bps: Float = 0
    
    /// 音频采样率
    public var audioSampleRate: Int32 = 0
    
    /// 宽
    public var width: Float = 0
    
    /// 高
    public var height: Float = 0
}


extension VideoInfo {
    public override var description: String {
        func fileSize(size: UInt64) -> String {
            var _size = Float(size)
            if _size < 1024 {
                return "\(_size)B"
            }
            _size /= 1024
            if _size < 1024 {
                return "\(_size)KB"
            }
            _size /= 1024
            if _size < 1024 {
                return "\(_size)M"
            } else {
                return "\(_size/1024.0)G"
            }
        }
        let str = "<VideoInfo> \n\tfilePath: \(filePath), \n\tduration: \(duration), \n\tfps: \(fps), \n\tfileSize: \(fileSize(size: self.fileSize)), \n\tbps: \(bps), \n\taudioSampleRate: \(audioSampleRate), \n\tsize: {\(width), \(height)}"
        return str
    }
}

public class VideoInfoReader: NSObject {
    
    private let videoPath: String!
    private let asset: AVURLAsset!
    
    public init(videoPath: String) {
        self.videoPath = videoPath
        self.asset = AVURLAsset(url: videoPath.fileURL)
    }
}


extension VideoInfoReader {
    
    /// 异步获取视频文件信息
    /// - Parameter handler: 结果回调
    public func asyncRead(completionHandler handler: @escaping (VideoInfo) -> Void) {
        let info = VideoInfo()
        info.filePath = asset.url.absoluteString
        
        let attribute = try? FileManager.default.attributesOfItem(atPath: info.filePath)
        if let attribute = attribute {
            if let size = attribute[FileAttributeKey.size] as? UInt64 {
                info.fileSize = size
            }
        }
        
        let group = DispatchGroup()
        
        let assetKeys = AssetKeyPath.stringKeys(from: [.duration])
        group.enter()
        asset.loadValuesAsynchronously(forKeys: assetKeys) {
            defer { group.leave() }
            if self.asset.statusOfValue(forKey: AssetKeyPath.duration.rawValue, error: nil) == .loaded {
                info.duration = CMTimeGetSeconds(self.asset.duration)
            } else {
                info.duration = 0
            }
        }
        let videoKeys = AssetKeyPath.stringKeys(from: [.nominalFrameRate, .estimatedDataRate])
        group.enter()
        if let videoTrack = asset.tracks(withMediaType: .video).first {
            videoTrack.loadValuesAsynchronously(forKeys: videoKeys) {
                defer { group.leave() }
                if videoTrack.statusOfValue(forKey: AssetKeyPath.nominalFrameRate.rawValue, error: nil) == .loaded {
                    info.fps = videoTrack.nominalFrameRate
                } else {
                    info.fps = 0
                }
                if videoTrack.statusOfValue(forKey: AssetKeyPath.estimatedDataRate.rawValue, error: nil) == .loaded {
                    info.bps = videoTrack.estimatedDataRate
                } else {
                    info.bps = 0
                }
                if videoTrack.statusOfValue(forKey: AssetKeyPath.naturalSize.rawValue, error: nil) == .loaded {
                    info.width = Float(videoTrack.naturalSize.width)
                    info.height = Float(videoTrack.naturalSize.height)
                } else {
                    info.width = 0
                    info.height = 0
                }
            }
        }
        let audioKeys = AssetKeyPath.stringKeys(from: [.naturalTimeScale])
        group.enter()
        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            audioTrack.loadValuesAsynchronously(forKeys: audioKeys) {
                defer { group.leave() }
                if audioTrack.statusOfValue(forKey: AssetKeyPath.naturalTimeScale.rawValue, error: nil) == .loaded {
                    info.audioSampleRate = audioTrack.naturalTimeScale
                } else {
                    info.audioSampleRate = 0
                }
            }
        }
        group.notify(queue: DispatchQueue.main) {
            handler(info)
        }
    }
}



extension VideoInfoReader {
    
    enum AssetKeyPath: String {
        // MARK: use in AVAsset
        /// 时长
        case duration
        
        // MARK: use in AVAssetTrack
        /// 格式描述
        case formatDescriptions
        /// 时间范围，如果有延迟，那么`start`将 > 0
        case timeRange
        /// 采样率
        case naturalTimeScale
        /// 总采样字节大小
        case totalSampleDataLength
        /// 预计码率: bits/s
        case estimatedDataRate
        /// 尺寸，视频返回分辨率
        case naturalSize
        /// 音量大小
        case preferredVolume
        /// 帧率
        case nominalFrameRate
        /// 矩阵转换
        case preferredTransform
        
        // MARK: general useful in AVAsset and AVAssetTrack
        case metadata
        case commonMetadata
        case availableMetadataFormats
        
        
        static func stringKeys(from keyPaths: [AssetKeyPath]) -> [String] {
            let keys = keyPaths.map {
                $0.rawValue
            }
            return keys
        }
    }
}
