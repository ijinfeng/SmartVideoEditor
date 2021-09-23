//
//  RecordViewController.swift
//  RecordViewController
//
//  Created by jinfeng on 2021/9/23.
//

import UIKit
import SnapKit

class RecordViewController: UIViewController {
    
    let record = VideoRecord.shared
    
    let recordButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        // Do any additional setup after loading the view.
        
        recordButton.setTitle("开始录制", for: .normal)
        recordButton.setTitle("停止录制", for: .selected)
        recordButton.setTitleColor(.blue, for: .normal)
        recordButton.setTitleColor(.blue, for: .selected)
        recordButton.layer.borderColor = UIColor.blue.cgColor
        recordButton.layer.borderWidth = 1
        view.addSubview(recordButton)
        
        recordButton.snp.makeConstraints { make in
            make.bottom.equalTo(-30)
            make.width.equalTo(80)
            make.height.equalTo(40)
            make.centerX.equalTo(view)
        }
        
        recordButton.addTarget(self, action: #selector(onClickRecord), for: .touchUpInside)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        record.startCollect(preview: self.view)
    }
    
    
    @objc func onClickRecord() {
        recordButton.isSelected = !record.isRecording
        if record.isRecording {
            record.stopRecord()
        } else {
            record.startRecord()
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
