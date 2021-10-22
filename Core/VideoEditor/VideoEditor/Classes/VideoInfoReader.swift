//
//  VideoInfoReader.swift
//  VideoEditor
//
//  Created by jinfeng on 2021/10/12.
//

import UIKit
import AVFoundation

public class VideoInfo: NSObject {
    /// 文件路径
    public var filePath: String = ""
    
    /// 时长
    public var duration: TimeInterval = 0
    
    /// 帧率
    public var fps: Float = 0
    
    /// 大小
    public var fileSize: UInt64 = 0
    
    /// 比特率
    public var bps: Float = 0
    
    /// 视频采样率
    public var videoTimeScale: Int32 = 0
    
    /// 音频采样率
    public var audioSampleRate: Int32 = 0
    
    /// 宽
    public var width: CGFloat = 0
    
    /// 高
    public var height: CGFloat = 0
    
    /// 旋转角度
    public var rotationAngle: CGFloat = 0
}

extension VideoInfo {
    public override var description: String {
        func fileSize(size: UInt64) -> String {
            let tunit: Float = 1024.0
            var _size = Float(size)
            if _size < tunit {
                return String(format: "%.2fB", _size)
            }
            _size /= tunit
            if _size < tunit {
                return String(format: "%.2fKB", _size)
            }
            _size /= tunit
            if _size < tunit {
                return String(format: "%.2fM", _size)
            } else {
                return String(format: "%.2fG", _size/tunit)
            }
        }
        let str = "- VideoInfo description: \n\t-filePath: \(filePath), \n\t-duration: \(duration), \n\t-fps: \(fps), \n\t-fileSize: \(fileSize(size: self.fileSize)), \n\t-bps: \(bps), \n\t-audioSampleRate: \(audioSampleRate), \n\t-width: \(width), \n\t-height: \(height), \n\t-rotationAngle: \(rotationAngle)"
        return str
    }
}

/// 视频信息读取类
public class VideoInfoReader: NSObject {
    
    private let videoPath: String!
    private let asset: AVAsset!
    private var info: VideoInfo?
    /// 如果是`true`，总是读取最新的，缓存中不保存
    public var alwaysReadNewestInfo = false
    
    private lazy var imageGenerator: AVAssetImageGenerator = AVAssetImageGenerator.init(asset: asset)
    
    /// 请求缩略图的误差范围，没有设置时将在系统默认误差范围内生成缩略图
    public var generateTolerance: TimeInterval? = 0
    
    public init(videoPath: String) {
        self.videoPath = videoPath
        self.asset = AVURLAsset(url: videoPath.fileURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
    }
    
    public init(asset: AVAsset) {
        self.videoPath = ""
        self.asset = asset
    }
    
    deinit {
        print("- VideoInfoReader deinit -")
    }
}

// MARK: 获取视频文件基本信息
extension VideoInfoReader {
    
    /// 如果已经缓存有文件信息，那么直接返回，否则异步去获取
    /// - Parameter handler: 结果回调
    public func tryAsyncRead(completionHandler handler: @escaping (VideoInfo) -> Void) {
        guard !alwaysReadNewestInfo else {
            asyncRead(completionHandler: handler)
            return
        }
        if let info = self.info {
            handler(info)
        } else {
            asyncRead(completionHandler: handler)
        }
    }
    
    /// 异步获取视频文件信息
    /// - Parameter handler: 结果回调
    public func asyncRead(completionHandler handler: @escaping (VideoInfo) -> Void) {
        let info = VideoInfo()
        info.filePath = videoPath
        
        if !info.filePath.isEmpty {
            let attribute = try? FileManager.default.attributesOfItem(atPath: videoPath)
            if let attribute = attribute {
                if let size = attribute[FileAttributeKey.size] as? UInt64 {
                    info.fileSize = size
                }
            }
        }
        
        let group = DispatchGroup()
        
        let assetKeys = AssetKeyPath.stringKeys(from: [.duration])
        group.enter()
        asset.loadValuesAsynchronously(forKeys: assetKeys) {
            defer { group.leave() }
            if self.asset.statusOfValue(forKey: AssetKeyPath.duration.rawValue, error: nil) == .loaded {
                info.duration = CMTimeGetSeconds(self.asset.duration)
                info.videoTimeScale = self.asset.duration.timescale
            } else {
                info.duration = 0
            }
        }
        let videoKeys = AssetKeyPath.stringKeys(from: [.nominalFrameRate, .estimatedDataRate, .naturalSize, .preferredTransform])
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
                    let size = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
                    info.width = size.width
                    info.height = size.height
                } else {
                    info.width = 0
                    info.height = 0
                }
                if videoTrack.statusOfValue(forKey: AssetKeyPath.preferredTransform.rawValue, error: nil) == .loaded {
                    let transform = videoTrack.preferredTransform
                    info.rotationAngle = transform.getTransformAngle()
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
        
        var fileSize: Int64 = 0
        if info.filePath.isEmpty {
            let videoTracks = asset.tracks(withMediaType: .video)
            let audioTracks = asset.tracks(withMediaType: .audio)
            for videoTrack in videoTracks {
                group.enter()
                let videoKeys = AssetKeyPath.stringKeys(from: [.totalSampleDataLength])
                videoTrack.loadValuesAsynchronously(forKeys: videoKeys) {
                    group.leave()
                    if videoTrack.statusOfValue(forKey: AssetKeyPath.totalSampleDataLength.rawValue, error: nil) == .loaded {
                        fileSize += videoTrack.totalSampleDataLength
                    }
                }
            }
            for audioTrack in audioTracks {
                group.enter()
                let audioKeys = AssetKeyPath.stringKeys(from: [.totalSampleDataLength])
                audioTrack.loadValuesAsynchronously(forKeys: audioKeys) {
                    group.leave()
                    if audioTrack.statusOfValue(forKey: AssetKeyPath.totalSampleDataLength.rawValue, error: nil) == .loaded {
                        fileSize += audioTrack.totalSampleDataLength
                    }
                }
            }
        }
        group.notify(queue: DispatchQueue.main) {
            if self.alwaysReadNewestInfo == false {
                if info.filePath.isEmpty {
                    info.fileSize = UInt64(fileSize)
                }
                self.info = info
            } else {
                self.info = nil
            }
            DispatchQueue.main.async {
                handler(info)
            }
        }
    }
    
    /// 如果已经缓存有文件信息，那么直接返回，否则同步去获取
    /// - Returns: 文件信息
    public func trySyncRead() -> VideoInfo {
        guard !alwaysReadNewestInfo else {
            return syncRead()
        }
        if let info = self.info {
            return info
        } else {
            return syncRead()
        }
    }
    
    /// 同步获取视频文件信息
    /// - Returns: 文件信息
    public func syncRead() -> VideoInfo {
        let info = VideoInfo()
        info.filePath = videoPath
        
        if !info.filePath.isEmpty {
            let attribute = try? FileManager.default.attributesOfItem(atPath: videoPath)
            if let attribute = attribute {
                if let size = attribute[FileAttributeKey.size] as? UInt64 {
                    info.fileSize = size
                }
            }
        }
        
        info.duration = CMTimeGetSeconds(self.asset.duration)
        info.videoTimeScale = self.asset.duration.timescale
        
        if let videoTrack = asset.tracks(withMediaType: .video).first {
            info.fps = videoTrack.nominalFrameRate
            info.bps = videoTrack.estimatedDataRate
            let size = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
            info.width = size.width
            info.height = size.height
            let transform = videoTrack.preferredTransform
            info.rotationAngle = transform.getTransformAngle()
        }
       
        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            info.audioSampleRate = audioTrack.naturalTimeScale
        }
        
        if info.filePath.isEmpty {
            let videoTracks = asset.tracks(withMediaType: .video)
            let audioTracks = asset.tracks(withMediaType: .audio)
            var fileSize: Int64 = 0
            for videoTrack in videoTracks {
                fileSize += videoTrack.totalSampleDataLength
            }
            for audioTrack in audioTracks {
                fileSize += audioTrack.totalSampleDataLength
            }
            info.fileSize = UInt64(fileSize)
        }
        
        if self.alwaysReadNewestInfo == false {
            self.info = info
        } else {
            self.info = nil
        }
        
        return info
    }
}

public class VideoTrackInfo: VideoInfo {
    public fileprivate(set) var hasVideoTrack: Bool!
    public fileprivate(set) var videoTrackCount: UInt!
    public fileprivate(set) var videoTracks: [AVAssetTrack]!
    
    public fileprivate(set) var hasAudioTrack: Bool!
    public fileprivate(set) var audioTrackCount: UInt!
    public fileprivate(set) var audioTracks: [AVAssetTrack]!
    
    public init(videoInfo: VideoInfo) {
        super.init()
        filePath = videoInfo.filePath
        duration = videoInfo.duration
        fps = videoInfo.fps
        fileSize = videoInfo.fileSize
        bps = videoInfo.bps
        videoTimeScale = videoInfo.videoTimeScale
        audioSampleRate = videoInfo.audioSampleRate
        width = videoInfo.width
        height = videoInfo.height
    }
}

extension VideoTrackInfo {
    public override var description: String {
        var str = super.description
        str += ", \n\t-hasVideoTrack: \(hasVideoTrack!), \n\t-videoTrackCount: \(videoTrackCount!), \n\t-videoTracks: \(videoTracks!), \n\t-hasAudioTrack: \(hasAudioTrack!), \n\t-audioTrackCount: \(audioTrackCount!), \n\t-audioTracks: \(audioTracks!)"
        return str
    }
}

// MARK: 读取视频的音轨和视轨信息
extension VideoInfoReader {
    public func asyncReadTrack(completionHandler handler: @escaping (VideoTrackInfo) -> Void) {
        tryAsyncRead { info in
            let trackInfo = VideoTrackInfo.init(videoInfo: info)
            
            let videoTracks = self.asset.tracks(withMediaType: .video)
            trackInfo.hasVideoTrack = !videoTracks.isEmpty
            trackInfo.videoTrackCount = UInt(videoTracks.count)
            trackInfo.videoTracks = videoTracks
            
            let audioTracks = self.asset.tracks(withMediaType: .audio)
            trackInfo.hasAudioTrack = !audioTracks.isEmpty
            trackInfo.audioTrackCount = UInt(audioTracks.count)
            trackInfo.audioTracks = audioTracks
            handler(trackInfo)
        }
    }
    
    public func syncReadTrack() -> VideoTrackInfo {
        let info = trySyncRead()
        let trackInfo = VideoTrackInfo.init(videoInfo: info)
        
        let videoTracks = self.asset.tracks(withMediaType: .video)
        trackInfo.hasVideoTrack = !videoTracks.isEmpty
        trackInfo.videoTrackCount = UInt(videoTracks.count)
        trackInfo.videoTracks = videoTracks
        
        let audioTracks = self.asset.tracks(withMediaType: .audio)
        trackInfo.hasAudioTrack = !audioTracks.isEmpty
        trackInfo.audioTrackCount = UInt(audioTracks.count)
        trackInfo.audioTracks = audioTracks
        
        return trackInfo
    }
}

// MARK: 获取视频流的缩略图
extension VideoInfoReader {
    
    public typealias GenerateImagesHandler = (_ requestTime: TimeInterval, _ outputImage: CGImage?, _ index: Int, _ total: Int) -> Bool
    public typealias GenerateImageHandler = (_ outputImage: CGImage?) -> Void
    
    /// 通过给定时间轴上的时间节点来获取缩略图
    /// - Parameters:
    ///   - times: 时间节点的数组
    ///   - maximumSize: 生成缩略图的最大尺寸，`zero` 表示不缩放
    ///   - handler: 每获取一张会回调一次，返回 `true` 继续获取下一张
    public func generateImages(times: [TimeInterval], maximumSize: CGSize = .zero, async handler: @escaping GenerateImagesHandler) {
        guard times.count > 0 else {
            return
        }
        tryAsyncRead { info in
            self.imageGenerator.appliesPreferredTrackTransform = true
            if let generateTolerance = self.generateTolerance {
                let to = CMTimeMakeWithSeconds(generateTolerance, preferredTimescale: info.videoTimeScale)
                self.imageGenerator.requestedTimeToleranceAfter = to
                self.imageGenerator.requestedTimeToleranceBefore = to
            }
            self.imageGenerator.maximumSize = maximumSize
            var vtimes: [NSValue] = []
            for time in times {
                let t = CMTime(value: CMTimeValue(time * Double(info.videoTimeScale)), timescale: info.videoTimeScale)
                if t <= self.asset.duration {
                    vtimes.append(NSValue.init(time: t))
                }
            }
            var index = 0
            let total = vtimes.count
            if vtimes.count == 0 {
                print("input times is invalid")
                return
            }
            self.imageGenerator.generateCGImagesAsynchronously(forTimes: vtimes) { requestTime, image, acturalTime, result, error in
                DispatchQueue.main.async {
                    var outputImage: CGImage? = nil
                    if result == .succeeded && image != nil {
                        outputImage = image!
                    }
                    let `continue` = handler(CMTimeGetSeconds(requestTime), outputImage, index, total)
                    if `continue` == false {
                        self.imageGenerator.cancelAllCGImageGeneration()
                    }
                    index += 1
                }
            }
        }
    }
    
    /// 通过给定时间间隔来获取缩略图
    /// - Parameters:
    ///   - interval: 时间间隔，如每隔 1s 生成一张图
    ///   - maximumSize: 生成缩略图的最大尺寸，`zero` 表示不缩放
    ///   - handler: 每获取一张会回调一次，返回 `true` 继续获取下一张
    public func generateImages(by interval: TimeInterval, maximumSize: CGSize = .zero, async handler: @escaping GenerateImagesHandler) {
        guard interval > 0 else {
            return
        }
        tryAsyncRead { info in
            let dur = info.duration
            var times: [TimeInterval] = []
            for time in stride(from: 0, through: dur, by: interval) {
                times.append(time)
            }
            self.generateImages(times: times, maximumSize: maximumSize, async: handler)
        }
    }
    
    /// 获取指定时间节点的缩略图
    /// - Parameters:
    ///   - time: 时间节点
    ///   - maximumSize: 生成缩略图的最大尺寸，`zero` 表示不缩放
    ///   - handler: 获取到缩略图后的回调
    public func generateImage(at time: TimeInterval, maximumSize: CGSize = .zero, async handler: @escaping GenerateImageHandler) {
        generateImages(times: [time], maximumSize: maximumSize) { requestTime, outputImage, index, total in
            handler(outputImage)
            return true
        }
    }
    
    /// 获取视频的首帧图片
    /// - Parameters:
    ///    - maximumSize: 生成缩略图的最大尺寸，`zero` 表示不缩放
    /// - Returns: 缩略图
    public func getFirstFrameImage(maximumSize: CGSize = .zero, async handler: @escaping GenerateImageHandler) {
        generateImage(at: 0, maximumSize: maximumSize) { outputImage in
            handler(outputImage)
        }
    }
    
    /// 获取视频的最后一帧图片
    /// - Parameters:
    ///    - maximumSize: 生成缩略图的最大尺寸，`zero` 表示不缩放
    /// - Returns: 缩略图
    public func getLastFrameImage(maximumSize: CGSize = .zero, async handler: @escaping GenerateImageHandler) {
        tryAsyncRead { info in
            self.generateImage(at: info.duration, maximumSize: maximumSize) { outputImage in
                handler(outputImage)
            }
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

/// https://www.jianshu.com/p/ca7f9bc62429/
/// CGAffineTransform
/// | a  b  0 |
/// | c  d  0 |
/// | tx ty 1 |
///
/// CGAffineTransformIdentity： (1, 0, 0, 1, 0, 0)
///
/// 点集转换
/// x' = ax + cy + tx
/// y' = bx + dy + ty
/// tx控制x轴方向上的平移，ty控制y轴方向上的平移
///
/// 旋转 'M_PI * 0.5'
/// CGAffineTransformMake(cos(M_PI * 0.5), sin(M_PI * 0.5), -sin(M_PI * 0.5), cos(M_PI * 0.5), 0, 0)
extension CGAffineTransform {
    
    /// 获取旋转的角度
    /// - Returns: 角度: 0, 90, 180, 270
    public func getTransformAngle() -> CGFloat {
        var angle: CGFloat = 0
        if a == 0 && b == 1 && c == -1 && d == 0 {
            angle = 90
        } else if a == 0 && b == -1 && c == 1 && d == 0 {
            angle = 270
        } else if a == 1 && b == 0 && c == 0 && d == 1 {
            angle = 0
        } else if a == -1 && b == 0 && c == 0 && d == -1 {
            angle = 180
        } else {
            // other angle
        }
        return angle
    }
}
