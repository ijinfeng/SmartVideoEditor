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
    
    var timeLine: TimeLine!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        exportButton = UIButton()
        exportButton.setTitle("导出", for: .normal)
        exportButton.setTitleColor(.red, for: .normal)
        exportButton.sizeToFit()
        navigationItem.titleView = exportButton
        exportButton.addTarget(self, action: #selector(onClickExport), for: .touchUpInside)
        
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "添加贴纸", style: .plain, target: self, action: #selector(onClickAdd))
        
        
        let Line20 = UIView()
        Line20.backgroundColor = .red
        Line20.frame = CGRect(x: 20, y: 0, width: 1, height: view.frame.height)
        UIApplication.shared.keyWindow?.addSubview(Line20)

        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        buildCustomVideoComposition()

    }


    func buildCustomVideoComposition() {
        let path = Bundle.main.path(forResource: "guide", ofType: "mp4")
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
        timeLine.contentMode = .scaleAspectFill
        timeLine.renderSize = CGSize(width: 1800, height: 1800)
        timeLine.backgroundColor = UIColor.blue
        
        self.timeLine = timeLine
        
        // 静态贴纸
        let uiimage = UIImage(named: "biaozhun")!
        let ciimage = CIImage(cgImage: uiimage.cgImage!)
        let image = StaticImageOverlay.init(image: ciimage)
        image.timeRange = CMTimeRange.init(start: CMTime.init(value: 0, timescale: 1), end: CMTime.init(value: 2, timescale: 1))
        image.frame = CGRect(x: 20, y: 20, width: 160, height: 60)
//        timeLine.insert(element: image)
        
        
        
        // 动态贴纸
        let filePath = Bundle.main.path(forResource: "shafa", ofType: "gif") ?? ""
        let gif = DynamicImageOverlay(filePath: filePath)
        gif.timeRange = CMTimeRange.init(start: CMTime.init(value: 1, timescale: 1), duration: CMTime.init(value: 8, timescale: 1))
        gif.frame = CGRect(x: 20, y: 100, width: 100, height: 80)
//        timeLine.insert(element: gif)
        
        
        // 动画贴纸
        let overlay = AnimationOverlay(image: ciimage)
        overlay.timeRange = CMTimeRange.init(start: CMTime.init(value: 0, 1), duration: CMTime.init(value: 6, 1))
        overlay.frame = CGRect(x: 20, y: 0, width: 80, height: 80)
        // 渐变动画
        let an = BasicAnimation()
        an.duration = CMTime.init(value: 3, 2)
        an.isAutoreverse = true
        an.isRepeat = false
        an.type = .opacity
        an.from = 0.5
        an.to = 1
//        overlay.add(animation: an, for: nil)
        // 旋转动画
        let rotate = BasicAnimation()
        rotate.type = .rotate
        rotate.from = 30/180
        rotate.to = 1
//        overlay.add(animation: rotate, for: "roatt")
        // 缩放动画
        let sacle = BasicAnimation()
        sacle.type = .scale
        sacle.from = 1.0
        sacle.to = 2.0
//        overlay.add(animation: sacle, for: "sacle")
        
        // 位移
        let tt = BasicAnimation()
        tt.type = .translate
        tt.from = CGPoint.zero
        tt.to = CGPoint(x: -20, y: 0)
        tt.duration = CMTime.init(value: 1, 2)
        tt.isAutoreverse = true
//        overlay.add(animation: tt, for: "tt")
        
        // 关键帧动画
        let key1 = KeyFrameAnimation()
        key1.type = .opacity
        key1.values = [0.5, 1, 0.2, 1, 0.5]
        key1.keyTimes = nil
        overlay.add(animation: key1, for: "k1")

        let key2 = KeyFrameAnimation()
        key2.type = .translate
        key2.values = [CGPoint(x: 50, y: 50),CGPoint(x: 0, y: 0),CGPoint(x: 50, y: 100),CGPoint(x: -20, y: 30) ]
        overlay.add(animation: key2, for: "k2")

        timeLine.insert(element: overlay)
        
        
        let builder = VideoCompositionBuilder(exist: nil)
        let videoCompostion = builder.buildVideoCompositon(with: timeLine)
        return videoCompostion
    }
    
    @objc func onClickAdd() {
        
        
        
        
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
