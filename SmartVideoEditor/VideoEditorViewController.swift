//
//  VideoEditorViewController.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/10/12.
//

import UIKit
import AVFoundation
import VideoEditor

class VideoEditorViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        if let path = Bundle.main.path(forResource: "vap", ofType: "mp4") {
            let asset = AVAsset(url: URL(fileURLWithPath: path))
            print("dur: \(asset.duration)")
            

            
            
            let reader = VideoInfoReader.init(videoPath: path)
            reader.asyncRead { info in
                print(info)
            }
        
            
//            CMVideoFormatDescription
            if let track = asset.tracks(withMediaType: .video).first {
                print("video============")
                print(track.formatDescriptions)
                print(track.timeRange)
                print(track.naturalTimeScale)
                print(track.estimatedDataRate)
                print(track.naturalSize)
                print(track.preferredVolume)
                print(track.nominalFrameRate)
                print(track.totalSampleDataLength)
                print(track.metadata)
            }
            if let track = asset.tracks(withMediaType: .audio).first {
                print("audio============")
                print(track.formatDescriptions)
                print(track.timeRange)
                print(track.naturalTimeScale)
                print(track.estimatedDataRate)
                print(track.naturalSize)
                print(track.preferredVolume)
                print(track.nominalFrameRate)
                print(track.totalSampleDataLength)
                print(track.metadata)
            }
            
        }
       
        
        
    }
   
}
