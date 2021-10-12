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
            
//            let attribute = try? FileManager.default.attributesOfItem(atPath: path)
//            if let attribute = attribute {
//                if let size = attribute[FileAttributeKey.size] as? UInt64 {
//                    print("size=\(size)")
//                }
//            }
//
          //  /Users/Cranz/Library/Developer/Xcode/DerivedData/SmartVideoEditor-bexvfvmaspimtuamcfowcddiipps/Build/Products/Debug-iphonesimulator/SmartVideoEditor.app/vap.mp4
            
        // file:///Users/Cranz/Library/Developer/CoreSimulator/Devices/29DE5B13-7EAB-4DD9-B830-C5FDF944111F/data/Containers/Bundle/Application/66706578-BF76-4170-A6E0-A103D0CED827/SmartVideoEditor.app/vap.mp4
            let reader = VideoInfoReader.init(videoPath: "/Users/Cranz/Library/Developer/Xcode/DerivedData/SmartVideoEditor-bexvfvmaspimtuamcfowcddiipps/Build/Products/Debug-iphonesimulator/SmartVideoEditor.app/vap.mp4")
            reader.asyncRead { info in
                print(info)
            }
            
        }
       
        
        
    }
   
}
