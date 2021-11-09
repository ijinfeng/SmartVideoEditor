//
//  CustomVideoCompositionViewController.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/11/8.
//

import UIKit
import AVFoundation
import AVKit
import VFCabbage
import VideoEditor

class CustomVideoCompositionViewController: UIViewController {

    
    var playerItem: AVPlayerItem?
    var exportButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        exportButton = UIButton()
        exportButton.setTitle("导出", for: .normal)
        exportButton.setTitleColor(.red, for: .normal)
        exportButton.sizeToFit()
        navigationItem.titleView = exportButton
        exportButton.addTarget(self, action: #selector(onClickExport), for: .touchUpInside)
        
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        buildCustomVideoComposition()
        
        
//        let path = Bundle.main.path(forResource: "bamboo", ofType: "mp4")
//
//        let URL = URL(fileURLWithPath: path ?? "")
//        let asset = AVURLAsset(url: URL)
//
//        let item = AVPlayerItem.init(url: URL)
//
//        let videoComposition = AVMutableVideoComposition.init(propertiesOf: asset)
//        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
//        videoComposition.renderSize = CGSize(width: 540, height: 960)
//        videoComposition.customVideoCompositorClass = VideoCustomComposition.self
//
//        // 43M ，内存飙升到120M左右
//        item.videoComposition = videoComposition
//
//        let vc = AVPlayerViewController.init()
//        vc.player = AVPlayer.init(playerItem: item)
//        navigationController?.pushViewController(vc, animated: true)
    }


    func buildCustomVideoComposition() {
        let path = Bundle.main.path(forResource: "bamboo", ofType: "mp4")
        let URL = URL(fileURLWithPath: path ?? "")
        let asset = AVURLAsset(url: URL)
        
        
        
        let item = AVPlayerItem.init(asset: asset)
        playerItem = item
        
        item.videoComposition = buildVideoComposition()
        
        
        let vc = AVPlayerViewController.init()
        vc.player = AVPlayer.init(playerItem: item)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func buildVideoComposition() -> AVVideoComposition? {
        guard let asset = playerItem?.asset else {
            return nil
        }
        let timeLine = TimeLine(asset: asset)
        
        let uiimage = UIImage(named: "biaozhun")!
        let ciimage = CIImage(cgImage: uiimage.cgImage!)

        let image = StaticImageOverlay.init(image: ciimage)
        image.timeRange = CMTimeRange.init(start: CMTime.init(value: 2, timescale: 1), end: CMTime.init(value: 4, timescale: 1))
        image.frame = CGRect(x: 20, y: 100, width: 60, height: 60)
        timeLine.insert(element: image)
        
        let builder = VideoCompositionBuilder(exist: nil)
        let videoCompostion = builder.buildVideoCompositon(with: timeLine)
        return videoCompostion
    }
    
    
    @objc func onClickExport() {
        
        guard let asset = playerItem?.asset else {
            return
        }
        let path = VideoRecordConfig.defaultRecordOutputDirPath
        FileHelper.createDir(at: path)
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HH:mm:ss"
        let videoName = f.string(from: Date())
        let outputURL = path + "\(videoName).mp4"
        do {
            print("开始导出....")
            
            let export = AVAssetExportSession.init(asset: asset, presetName: AVAssetExportPresetHighestQuality)
            export?.outputURL = outputURL.fileURL
            export?.outputFileType = .mp4
            export?.shouldOptimizeForNetworkUse = true
            export?.videoComposition = buildVideoComposition()
            export?.exportAsynchronously {
                DispatchQueue.main.async {
                    switch export!.status {
                    case .completed:
                        print("导出成功")
                        
                        self.exportButton.setTitle("导出成功", for: .normal)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.exportButton.setTitle("添加贴图", for: .normal)
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
