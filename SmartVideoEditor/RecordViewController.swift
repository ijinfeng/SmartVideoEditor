//
//  RecordViewController.swift
//  RecordViewController
//
//  Created by jinfeng on 2021/9/23.
//

import UIKit
import SnapKit
import AlertMaker

class RecordViewController: UIViewController {
    
    let record = VideoRecord.shared
    
    let closeButton = UIButton()
    
    let recordButton = UIButton()
    
    let rotateButton = UIButton()
    
    let exportButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        
        closeButton.setImage(UIImage.init(named: "YJFVideoClose"), for: .normal)
        closeButton.addTarget(self, action: #selector(onClickClose), for: .touchUpInside)
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(20)
            make.left.equalTo(20)
            make.size.equalTo(CGSize(width: 32, height: 32))
        }
        
        rotateButton.setImage(UIImage(named: "YJFVideoReverse"), for: .normal)
        rotateButton.addTarget(self, action: #selector(onClickRotate), for: .touchUpInside)
        view.addSubview(rotateButton)
        rotateButton.snp.makeConstraints { make in
            make.right.equalTo(-12)
            make.top.equalTo(100)
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
        
        // Do any additional setup after loading the view.
        
        recordButton.setTitle("开始录制", for: .normal)
        recordButton.setTitle("停止录制", for: .selected)
        recordButton.setTitleColor(.white, for: .normal)
        recordButton.setTitleColor(.white, for: .selected)
        recordButton.backgroundColor = .red
        view.addSubview(recordButton)
        
        recordButton.snp.makeConstraints { make in
            make.bottom.equalTo(-30)
            make.width.equalTo(80)
            make.height.equalTo(40)
            make.centerX.equalTo(view)
        }
        
        recordButton.addTarget(self, action: #selector(onClickRecord), for: .touchUpInside)
        
        exportButton.setImage(UIImage(named: "YJFVideoFinish"), for: .normal)
        view.addSubview(exportButton)
        exportButton.addTarget(self, action: #selector(onClickExportVideo), for: .touchUpInside)
        
        exportButton.snp.makeConstraints { make in
            make.centerY.equalTo(recordButton)
            make.left.equalTo(recordButton.snp_rightMargin).offset(20)
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        record.startCollect(preview: self.view)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        record.stopRecord()
        record.stopCollect()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    
    
}

extension RecordViewController {
    @objc func onClickRecord() {
        recordButton.isSelected = !record.isRecording
        record.delegate = self
        if record.isRecording {
            record.stopRecord()
        } else {
            try? record.startRecord()
        }
    }

    @objc func onClickClose() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func onClickRotate() {
        record.switchCamera(to: record.collector.camera == .back ? .front : .back)
    }
    
    @objc func onClickExportVideo() {
        do {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd-HH:mm:ss"
            let videoName = f.string(from: Date())
            try record.partsManager.mixtureAllParts(outputPath: VideoRecordConfig.defaultRecordOutputDirPath + "/\(videoName).mp4") { success in
                print(success)
                if success {
                    XCCustomAlertMaker.alert().setTitle("成功了").addDefaultAction("确定", action: nil).present(from: self)
                }
            }
        } catch {
            print(error)
            XCCustomAlertMaker.alert().setTitle("失败了").setContent("\(error)").addDefaultAction("确定", action: nil).present(from: self)
        }
    }
}


extension RecordViewController: VideoRecordDelegate {
    func didStartRecord(outputURL: URL) {
        
    }
    
    func didFinishRecord(outputURL: URL) {
        
    }
}
