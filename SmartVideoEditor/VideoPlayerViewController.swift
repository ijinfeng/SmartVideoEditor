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
        
        
        item.forwardPlaybackEndTime = CMTime.init(value: 3, timescale: 1)
        
        let playerLayer = AVPlayerLayer.init(player: player)
        playerLayer.frame = view.bounds
        view.layer.insertSublayer(playerLayer, at: 0)
        
        player.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(didPlayEnd), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
        
        
        if let asset = player.currentItem?.asset {
            let options = asset.availableMediaCharacteristicsWithMediaSelectionOptions
            for o in options {
                print(o)
                
                
                print("=======")
                if let group = asset.mediaSelectionGroup(forMediaCharacteristic: o) {
                    for o in group.options {
                        print(o.displayName)
                    }
                }
                
            }
        }
        
        
       
//
//        let mp = MPVolumeView()
//        mp.frame = view.bounds
//        mp.sizeToFit()
//        view.addSubview(mp)
//        print(mp)
        
        
//        let reader = AVAssetReader.init(asset: AVAsset.init(url: URL))
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
