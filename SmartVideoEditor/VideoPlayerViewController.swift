//
//  VideoPlayerViewController.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/10/14.
//

import UIKit
import AVFoundation
import MediaPlayer
import AVKit
import AVKit.AVPlayerViewController
import VideoEditor

class VideoPlayerViewController: UIViewController {

    
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var slider: UISlider!
    
    var isPlaying: Bool = false

    var builder: VideoOverlayBuilder!
    
    var timeLabel: UILabel = UILabel()
    
    var expoertButton: UIButton = UIButton()
    
    var playerItem: AVPlayerItem!
    
    var addbutton = UIButton()
    
    deinit {
        print("=============deinit==========")
        player.removeObserver(self, forKeyPath: "status")
        player.currentItem?.removeObserver(self, forKeyPath: "duration")
        player.pause()
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        navigationController?.setNavigationBarHidden(true, animated: true)
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        navigationController?.setNavigationBarHidden(false, animated: true)
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        changeNavigationItem()
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        
        addbutton.setTitle("添加贴图", for: .normal)
        addbutton.sizeToFit()
        addbutton.setTitleColor(.white, for: .normal)
        addbutton.addTarget(self, action: #selector(onClickButton), for: .touchUpInside)
        
        navigationItem.titleView = addbutton
        
        
        
        
        let path = Bundle.main.path(forResource: "guide", ofType: "mp4")
        
        let URL = URL(fileURLWithPath: path ?? "")
        
        let item = AVPlayerItem.init(url: URL)
        self.playerItem = item
        
        player = AVPlayer.init(playerItem: item)

        let playerLayer = AVPlayerLayer.init(player: player)
        playerLayer.backgroundColor = UIColor.black.cgColor
        playerLayer.frame = view.bounds
        view.layer.insertSublayer(playerLayer, at: 0)
        self.playerLayer = playerLayer
        
        slider = UISlider()
        slider.frame = CGRect(x: 0, y: UIScreen.main.bounds.size.height - 88, width: view.bounds.size.width, height: 30)
        view.addSubview(slider)
        
        slider.addTarget(self, action: #selector(onSliderDidChange), for: .valueChanged)
        
        timeLabel.text = "00:00"
        timeLabel.textColor = .white
        view.addSubview(timeLabel)
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textAlignment = .center
        timeLabel.frame = CGRect(x: 0, y: slider.frame.minY + 25, width: view.frame.size.width, height: 25)
        
        
        
        
        player.addPeriodicTimeObserver(forInterval: CMTime.init(value: CMTimeValue(1), timescale: 10), queue: DispatchQueue.main) { [weak self] t in
//            print("tttt= \(CMTimeShow(t))")
            
            self?.slider.value = Float(CMTimeGetSeconds(t))
            
            let seconds = CMTimeGetSeconds(t)
            
            self?.timeLabel.text = "00:"+String(format: "%02.0f", seconds)
            
            
            
        }
        
        
        expoertButton.setTitle("导出视频", for: .normal)
        expoertButton.sizeToFit()
        expoertButton.setTitleColor(.white, for: .normal)
        expoertButton.addTarget(self, action: #selector(onLickExpoert), for: .touchUpInside)
        view.addSubview(expoertButton)
        expoertButton.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.top.equalTo(100)
        }
        
        
        builder = VideoOverlayBuilder.init(playerItem: item)
        playerLayer.apply(builder: builder)

        player.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        item.addObserver(self, forKeyPath: "duration", options: .new, context: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didPlayEnd), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    func logSyncLayer() {
        print("============================== BEGIN")
        print("currentTime: \(CMTimeShow(builder.syncLayer.playerItem!.currentTime()))")
        print("beginTime: \(builder.syncLayer.beginTime)")
        print("duration: \(builder.syncLayer.duration)")
//        print("syncLayer.subs: \(builder.syncLayer.sublayers)")
        print("present: \(builder.syncLayer.presentation())")
        print("============================== END \n\n")
    }
    
    override  func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let path = keyPath {
            if path == "status" && player.status == .readyToPlay {

                let duration = player.currentItem?.duration
                print(duration ?? .zero)
                navigationItem.rightBarButtonItem?.isEnabled = true
                print("准备好了--------")
            }
            if path == "duration" {
                if let duration = player.currentItem?.duration, duration > CMTime.zero {
                    slider.maximumValue = Float(CMTimeGetSeconds(duration))
                }
            }
        }
    }
    
    @objc func didPlayEnd() {
        print("播放结束")
        
        self.player.seek(to: .zero)
        self.player.play()
        
        
    }
    
    @objc func onClickPlayer() {
        isPlaying = !isPlaying
        if isPlaying {
            player.play()
        } else {
            player.pause()
        }
        changeNavigationItem()
    }
    
    func changeNavigationItem() {
        if isPlaying {
            navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .stop, target: self, action: #selector(onClickPlayer))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .play, target: self, action: #selector(onClickPlayer))
        }
    }
    
    @objc func onClickButton() {
        print("添加贴图======= \(CMTimeGetSeconds(player.currentTime()))")
        
        let text = NSMutableAttributedString.init(string: "你好好---")
        text.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20), NSAttributedString.Key.foregroundColor: UIColor.green], range: NSMakeRange(0, text.length))
        
        let range = CMTimeRange.init(start: player.currentTime(), duration: CMTime.init(value: 20, timescale: 10))
        
//        if arc4random() % 2 == 0 {
            builder.insert(text: text, rect: CGRect(x: 0, y: 100 + Int(arc4random()) % 300, width: 120, height: 40), timeRange: range, animation: nil)
//        } else {
            builder.insert(image: UIImage(named: "bailan")!, rect: CGRect(x: Int(arc4random() % 300), y: 60, width: 60, height: 60), timeRange: range) { begin, duration in
                let rotate = CABasicAnimation.init(keyPath: "transform.rotation.z")
                        rotate.toValue = Double.pi * 2
                        rotate.beginTime = CMTimeGetSeconds(begin)
                        rotate.duration = CMTimeGetSeconds(duration)
                        rotate.isRemovedOnCompletion = false
                        return [rotate]
            }
//            let filePath = Bundle.main.path(forResource: "shafa", ofType: "gif") ?? ""
            
//            builder.insert(gif: filePath, rect: CGRect(x: 100, y: 100 + Int(arc4random()) % 300, width: 160, height: 80), timeRange: range, animation: nil)
//        }
        
    }
    
    @objc func onSliderDidChange() {
        player.pause()
        isPlaying = false
        changeNavigationItem()
        
        let t = CMTime.init(seconds: Double(slider.value), preferredTimescale: player.currentItem!.duration.timescale)
        player.seek(to: t, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    // MARK: 导出视频
    @objc func onLickExpoert() {
//        let _path = Bundle.main.path(forResource: "vap", ofType: "mp4")
//        let URL = URL(fileURLWithPath: _path ?? "")
//        let asset = AVURLAsset.init(url: URL)
//        let composition = AVMutableComposition()
//        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
//            return
//        }
//        let videoComTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
//        try? videoComTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
//        if let audioTrack = asset.tracks(withMediaType: .audio).first {
//            let audioComTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
//            try? audioComTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: audioTrack, at: .zero)
//        }
//
//
//        let videoComposition = AVMutableVideoComposition()
//        let duration = asset.duration
//        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
//            return
//        }
//
//        var instructions: [AVMutableVideoCompositionInstruction] = []
//        let videoInstruction = AVMutableVideoCompositionInstruction()
//        videoInstruction.timeRange = CMTimeRange(start: .zero, duration: duration)
//        let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction.init(assetTrack: videoTrack)
//        videoInstruction.layerInstructions = [videoLayerInstruction]
//        instructions.append(videoInstruction)
//
//        videoComposition.instructions = instructions
//        videoComposition.renderSize = videoTrack.naturalSize
//        videoComposition.frameDuration = CMTime.init(value: 1, timescale: 30)
        
        let videoComposition = builder.getVideoComposition()
        videoComposition.apply(builer: builder)
        
//        let videoLayer = CALayer()
//        let animationLayer = CALayer()
//        animationLayer.isGeometryFlipped = true
//        animationLayer.addSublayer(videoLayer)
//
//        let renderSize = videoTrack.naturalSize
//
//        let renderRect = CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height)
//
//        videoLayer.frame = renderRect
//        animationLayer.frame = renderRect

//        builer.videoOverlayMap.forEach { (overlayId: OverlayId, overlay: VideoOverlay) in
//            let contentlayer = overlay.layerOfContent()
//            contentlayer.isHidden = true
//            contentlayer.frame = overlay.rectOfContent()
//            animationLayer.addSublayer(contentlayer)
//
//            builer.setOverlayActivityTime(overlayId: overlayId, overlayLayer: contentlayer, at: overlay.timeRange)
//        }
        
//        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool.init(postProcessingAsVideoLayer: videoLayer, in: animationLayer)
        
        
        
        let path = VideoRecordConfig.defaultRecordOutputDirPath
        FileHelper.createDir(at: path)
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HH:mm:ss"
        let videoName = f.string(from: Date())
        let outputURL = path + "\(videoName).mp4"
        do {
            print("开始导出....")
            
            let export = AVAssetExportSession.init(asset: playerItem.asset, presetName: AVAssetExportPresetHighestQuality)
            export?.outputURL = outputURL.fileURL
            export?.outputFileType = .mp4
            export?.shouldOptimizeForNetworkUse = true
            export?.videoComposition = videoComposition
            export?.exportAsynchronously {
                DispatchQueue.main.async {
                    switch export!.status {
                    case .completed:
                        print("导出成功")
                        
                        self.addbutton.setTitle("导出成功", for: .normal)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.addbutton.setTitle("添加贴图", for: .normal)
                        }
                        
                        
                    default:
#if DEBUG
                        if export!.error != nil {
                            print("====> export error detail:\n\t \(export!.error!)")
                        }
#endif
                    }
                }
            }
//            try VideoExport.exportVideo(assetURL: nil, asset: composition, outputURL: outputURL.fileURL, ouputFileType: .mp4, videoComposition: videoComposition) { finished in
//                print("导出\(finished)")
//            }
        } catch {
            print(error)
        }
    }
}


extension VideoPlayerViewController : CAAnimationDelegate {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
//        print("点击了++++++++++++")
//
//        CATransaction.begin()
//        CATransaction.setAnimationDuration(0)
        
//        let empty = CALayer()
        //        empty.isHidden = false
//        empty.frame = CGRect(x: Int(arc4random_uniform(200)), y: Int(arc4random_uniform(500)), width: 40, height: 40)
//        empty.backgroundColor = UIColor.red.cgColor
//        builder.syncLayer.addSublayer(empty)
//        self.testAn()
        
//        CATransaction.commit()
        
//        DispatchQueue.main.async {
//            self.testAn()
//        }
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            self.testAn()
//        }
    }
    
    /// 发现没显示是layer的presentLayer上没有添加进去我们的子layer
    
    func testAn() {
        
        
        logSyncLayer()
        
        view.layer.addSublayer(builder.syncLayer)
        builder.syncLayer.frame = view.bounds

        
        let textLayer = CATextLayer()
        textLayer.isHidden = false
        let string = NSMutableAttributedString.init(string: "Hello AV")
        string.addAttribute(NSAttributedString.Key.font, value:UIFont.systemFont(ofSize: 30), range: NSMakeRange(0, string.length))
        string.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: NSMakeRange(0, string.length))
        textLayer.string = string
        textLayer.frame = CGRect(x: Int(arc4random_uniform(200)), y: Int(arc4random_uniform(500)), width: 100, height: 60)
        builder.syncLayer.addSublayer(textLayer)

        print("在位置\(textLayer.frame)处添加")

//        let rotate = CABasicAnimation.init(keyPath: "transform.rotation.z")
//        rotate.fromValue = Double.pi
//        rotate.toValue = Double.pi * 2
//        rotate.beginTime = AVCoreAnimationBeginTimeAtZero
//        rotate.duration = 2
//        rotate.isRemovedOnCompletion = false
//        textLayer.add(rotate, forKey: "rotate")
//
//        let hidden = CABasicAnimation.init(keyPath: "hidden")
//        hidden.fromValue = false
//        hidden.toValue = false
//        hidden.beginTime = AVCoreAnimationBeginTimeAtZero
//        hidden.duration = 3
//        hidden.isRemovedOnCompletion = false
//        textLayer.add(hidden, forKey: "hidden")
        
        logSyncLayer()
    }
    
    func animationDidStart(_ anim: CAAnimation) {
        print("开始动画 - \(anim)")
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        print("停止动画 - \(anim)")
    }
}
