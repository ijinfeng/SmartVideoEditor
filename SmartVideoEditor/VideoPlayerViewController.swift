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


class VideoPlayerViewController: UIViewController {

    
    var player: AVPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
    
        let path = Bundle.main.path(forResource: "vap", ofType: "mp4")
        
        let URL = URL(fileURLWithPath: path ?? "")
        
        let item = AVPlayerItem.init(url: URL)
        
        
        player = AVPlayer.init(playerItem: item)

        
        let playerLayer = AVPlayerLayer.init(player: player)
        playerLayer.frame = view.bounds
        view.layer.insertSublayer(playerLayer, at: 0)
        
        
        
        let syncLayer = AVSynchronizedLayer(playerItem: item)
        syncLayer.frame = view.bounds
        
        let textLayer = CATextLayer()
        let string = NSMutableAttributedString.init(string: "Hello AV")
        string.addAttribute(NSAttributedString.Key.font, value:UIFont.systemFont(ofSize: 30), range: NSMakeRange(0, string.length))
        string.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: NSMakeRange(0, string.length))
        textLayer.string = string
        textLayer.bounds = CGRect(x: 0, y: 0, width: 100, height: 60)
        textLayer.position = CGPoint(x: view.size.width / 2, y: view.size.height / 2)
        syncLayer.addSublayer(textLayer)
        playerLayer.addSublayer(syncLayer)
        
        
        let rotate = CABasicAnimation.init(keyPath: "transform.rotation.z")
        rotate.toValue = Double.pi * 2
        rotate.beginTime = 2
        rotate.duration = 2
        rotate.isRemovedOnCompletion = false
        textLayer.add(rotate, forKey: "rotate")
        
        
        player.addObserver(self, forKeyPath: "status", options: .new, context: nil)
                
        NotificationCenter.default.addObserver(self, selector: #selector(didPlayEnd), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
            print("添加新的图层")
            let imageLayer = CALayer()
            imageLayer.opacity = 0
            imageLayer.frame = CGRect(x: 100, y: 200, width: 80, height: 80)
            imageLayer.contents = UIImage(named: "YJFMusicCollection")?.cgImage
            syncLayer.addSublayer(imageLayer)
            
            let an = CABasicAnimation.init(keyPath: "opacity")
            an.fromValue = 0
            an.toValue = 1
            an.beginTime = 3.5
            an.duration = 3
            an.isRemovedOnCompletion = false
            imageLayer.add(an, forKey: "opacity")
            
            let an2 = CABasicAnimation.init(keyPath: "opacity")
            an2.fromValue = 1
            an2.toValue = 0
            an2.beginTime = 6.5
            an2.duration = 2
            an2.isRemovedOnCompletion = false
            imageLayer.add(an2, forKey: "opacity2")
           
            
            
        }
    }
    
    
    override  func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let path = keyPath {
            if path == "status" && player.status == .readyToPlay {

                
                let duration = player.currentItem?.duration
                print(duration ?? .zero)
                player.play()
                print("start play")
            }
        }
    }
    
    @objc func didPlayEnd() {
        print("播放结束")
        
        self.player.seek(to: .zero)
        self.player.play()
        
        
    }
}
