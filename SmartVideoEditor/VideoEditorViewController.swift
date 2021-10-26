//
//  VideoEditorViewController.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/10/12.
//

import UIKit
import AVFoundation
import VideoEditor
import SnapKit
import QuickLook
import SwifterSwift
import AVKit
import VideoTransition

class MyCell: UICollectionViewCell {
    
    var image: UIImage? {
        didSet {
            if let image = self.image {
                imageView.image = image
            }
        }
    }
    
    private var imageView: UIImageView = UIImageView()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class VideoEditorViewController: UIViewController {
    private let showImageView = UIImageView()
    
    let collection: UICollectionView = UICollectionView.init(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    
    var images: [CGImage?] = []
    var total: Int = 0
    
    let itemSize = CGSize(width: 60, height: 60)
    
    var reader: VideoInfoReader?
    
    var avReader: AVAssetReader!
    
    var curTime: CMTime = .zero
    
    var needReadNextBuffer = false
    
    let queue = DispatchQueue.init(label: "read buffer")
    var player: AVPlayer!
    
    internal lazy var context: CIContext = {
        if #available(iOS 12.0, *) {
            return CIContext()
        } else {
            if let eaglContext = EAGLContext.init(api: EAGLRenderingAPI.openGLES2) {
                return CIContext.init(eaglContext: eaglContext)
            }
            return CIContext.init(options: nil)
        }
    }()
    
    let editor = TransitionComposition()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(showImageView)
        showImageView.snp.makeConstraints { make in
            make.top.equalTo(88)
            make.size.equalTo(CGSize(width: 300, height: 300))
            make.centerX.equalTo(view)
        }

        collection.delegate = self
        collection.dataSource = self
        collection.register(MyCell.self, forCellWithReuseIdentifier: "cell")
        
        if let layout = collection.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }
        
        view.addSubview(collection)
        collection.backgroundColor = .white
        collection.snp.makeConstraints { make in
            make.left.right.equalTo(view)
            make.bottom.equalTo(-80)
            make.height.equalTo(itemSize.height)
        }
        
        view.backgroundColor = .white
        
        
        
       
        
        
        
        
//        if let path = Bundle.main.path(forResource: "vap", ofType: "mp4") {
//            let asset = AVAsset(url: URL(fileURLWithPath: path))
//            print(asset)
//            // AVURLAsset
//            print("dur: \(asset.duration)")
//
//        // file:///Users/Cranz/Library/Developer/CoreSimulator/Devices/29DE5B13-7EAB-4DD9-B830-C5FDF944111F/data/Containers/Bundle/Application/66706578-BF76-4170-A6E0-A103D0CED827/SmartVideoEditor.app/vap.mp4
//            let scale = UIScreen.main.scale
//            reader = VideoInfoReader.init(videoPath: path)
//            reader?.generateImages(by: 0.5, maximumSize: CGSize(width: itemSize.width * scale, height: itemSize.height * scale)) { requestTime, outputImage, index, total in
//                self.total = total
//                self.images.append(outputImage)
//                print("- req: \(requestTime), \n index: \(index), \n total: \(total), \n outImage: \(outputImage == nil ? "nil":"image")")
//                self.collection.reloadData()
//                return true
//            }
//        }
        
        editor.renderSize = CGSize(width: 320, height: 400)
        
        let asset1 = AVURLAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "sample_clip1", ofType: "m4v") ?? ""), options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        let asset2 = AVURLAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "sample_clip2", ofType: "mov") ?? ""), options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        let asset3 = AVURLAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "vap", ofType: "mp4") ?? ""), options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        let asset4 = AVURLAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "bamboo", ofType: "mp4") ?? ""), options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        
        editor.add(asset: asset1, timeRange: CMTimeRangeMake(start: .zero, duration: CMTimeMake(value: 5, timescale: 1)))
        editor.add(asset: asset4, timeRange: CMTimeRangeMake(start: .zero, duration: CMTimeMake(value: 5, timescale: 1))) { item in
            item.intersectionTime = CMTime.init(value: 2, timescale: 1)
            item.type = .push
        }
        editor.add(asset: asset1, timeRange: CMTimeRangeMake(start: .zero, duration: CMTimeMake(value: 5, timescale: 1))) { item in
            item.intersectionTime = CMTime.init(value: 2, timescale: 1)
            item.type = .push
        }
        editor.add(asset: asset3, timeRange: CMTimeRangeMake(start: .zero, duration: CMTimeMake(value: 5, timescale: 1))) { item in
            item.intersectionTime = CMTime.init(value: 2, timescale: 1)
            item.type = .push
        }
        editor.contentMode = .fitToScale
    }
 
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let vc = AVPlayerViewController()
        vc.player = AVPlayer.init()
        self.player = vc.player
        navigationController?.pushViewController(vc, completion: nil)

        editor.buildTransitionComposition()
        let item = editor.getPlayerItem()
        vc.player?.replaceCurrentItem(with: item)
        
        
//        let composition = editor.composition
//        let outputPath = VideoRecordConfig.defaultRecordOutputDirPath + "/myvideo.mp4"
//        if !FileHelper.fileExists(at: VideoRecordConfig.defaultRecordOutputDirPath) {
//            FileHelper.createDir(at: VideoRecordConfig.defaultRecordOutputDirPath)
//        }
//
//
//        if FileHelper.fileExists(at: outputPath) {
//            FileHelper.removeFile(at: outputPath)
//        }
//        try? VideoExport.exportVideo(assetURL: nil, asset: composition, outputURL: outputPath.fileURL, filter: nil, videoComposition: editor.videoComposition, audioMix: editor.audioMix) { finished in
//            if finished {
//
//            }
//        }
        
    }
    
}

extension VideoEditorViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MyCell
        cell.image = UIImage(cgImage: self.images[indexPath.row]!)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        itemSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        let offsetX = scrollView.contentOffset.x
//        let boundsWidth = scrollView.contentSize.width
//
//        let info = reader!.trySyncRead()
//        let scale = offsetX / boundsWidth
//        let time = info.duration * scale
//        let cmt = CMTime.init(seconds: time, preferredTimescale: info.videoTimeScale)
//        objc_sync_enter(self)
//        curTime = cmt
//        needReadNextBuffer = true
//        objc_sync_exit(self)
        
//        self.player.seek(to: cmt) { finished in
//            if  finished {
//                self.player.pause()
//            }
//        }
//        self.player.seek(to: cmt, toleranceBefore: CMTime.init(seconds: 0, preferredTimescale: info.videoTimeScale), toleranceAfter: CMTime.init(seconds: 0, preferredTimescale: info.videoTimeScale)) { finished in
//            if  finished {
//                self.player.pause()
//            }
//        }
        
        
//        if (player.currentItem != nil) && !needReadNextBuffer {
//            needReadNextBuffer = true
//            player.pause()
//            player.currentItem!.reversePlaybackEndTime = CMTime.init(seconds: 3, preferredTimescale: info.videoTimeScale)
//            player.play()
//        }
        
        
//        reader?.tryAsyncRead(completionHandler: { info in
//            let time = info.duration * scale
//            self.reader?.generateImage(at: time, maximumSize: CGSize(width: 65, height: 100), async: { outputImage in
//                if outputImage == nil {
//                    print("nil+++++++++++++++")
//                }
//                if let image = outputImage {
//                    self.showImageView.image = UIImage(cgImage: image)
//                }
//            })
//        })
    }
}
 

