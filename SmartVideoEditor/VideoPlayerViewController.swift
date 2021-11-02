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
import VideoVisualEffects

class VideoPlayerViewController: UIViewController {

    
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var slider: UISlider!
    
    var isPlaying: Bool = false

    var builder: VideoOverlayBuilder!
    
    var timeLabel: UILabel = UILabel()
    
    var expoertButton: UIButton = UIButton()
    
    var playerItem: AVPlayerItem!
    
    deinit {
        print("=============deinit==========")
        player.removeObserver(self, forKeyPath: "status")
        player.currentItem?.removeObserver(self, forKeyPath: "duration")
        player.pause()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        changeNavigationItem()
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        let button = UIButton()
        button.setTitle("添加贴图", for: .normal)
        button.sizeToFit()
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(onClickButton), for: .touchUpInside)
        
        navigationItem.titleView = button
        
        
        
        
        let path = Bundle.main.path(forResource: "vap", ofType: "mp4")
        
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
        
        

//
        player.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        item.addObserver(self, forKeyPath: "duration", options: .new, context: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didPlayEnd), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
//
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
//            print("添加新的图层")
//            let imageLayer = CALayer()
//            imageLayer.opacity = 0
//            imageLayer.frame = CGRect(x: 100, y: 200, width: 80, height: 80)
//            imageLayer.contents = UIImage(named: "YJFMusicCollection")?.cgImage
//            syncLayer.addSublayer(imageLayer)
//
//            let an = CABasicAnimation.init(keyPath: "opacity")
//            an.fromValue = 0
//            an.toValue = 1
//            an.beginTime = 3.5
//            an.duration = 3
//            an.isRemovedOnCompletion = false
//            imageLayer.add(an, forKey: "opacity")
//
//            let an2 = CABasicAnimation.init(keyPath: "opacity")
//            an2.fromValue = 1
//            an2.toValue = 0
//            an2.beginTime = 6.5
//            an2.duration = 2
//            an2.isRemovedOnCompletion = false
//            imageLayer.add(an2, forKey: "opacity2")
           
            
//        }
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
//            builder.insert(text: text, rect: CGRect(x: 0, y: 100 + Int(arc4random()) % 300, width: 120, height: 40), timeRange: range, animation: nil)
//        } else {
            builder.insert(image: UIImage(named: "bailan")!, rect: CGRect(x: Int(arc4random() % 300), y: 100 + Int(arc4random()) % 300, width: 60, height: 60), timeRange: range) { begin, duration in
                let rotate = CABasicAnimation.init(keyPath: "transform.rotation.z")
                        rotate.toValue = Double.pi * 2
                        rotate.beginTime = CMTimeGetSeconds(begin)
                        rotate.duration = CMTimeGetSeconds(duration)
                        rotate.isRemovedOnCompletion = false
                        return [rotate]
            }
            let filePath = Bundle.main.path(forResource: "shafa", ofType: "gif") ?? ""
            
            builder.insert(gif: filePath, rect: CGRect(x: 100, y: 100 + Int(arc4random()) % 300, width: 160, height: 80), timeRange: range, animation: nil)
//        }
        
    }
    
    @objc func onSliderDidChange() {
        player.pause()
        isPlaying = false
        changeNavigationItem()
        
        let t = CMTime.init(seconds: Double(slider.value), preferredTimescale: player.currentItem!.duration.timescale)
        player.seek(to: t, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    @objc func onLickExpoert() {
        
    }
}


extension VideoPlayerViewController : CAAnimationDelegate {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        print("点击了++++++++++++")
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        
//        let empty = CALayer()
        //        empty.isHidden = false
//        empty.frame = CGRect(x: Int(arc4random_uniform(200)), y: Int(arc4random_uniform(500)), width: 40, height: 40)
//        empty.backgroundColor = UIColor.red.cgColor
//        builder.syncLayer.addSublayer(empty)
        self.testAn()
        
        CATransaction.commit()
        
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
