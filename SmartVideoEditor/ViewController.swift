//
//  ViewController.swift
//  SmartVideoEditor
//
//  Created by JinFeng on 2021/9/20.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func onClickRecord(_ sender: Any) {
        let vc = RecordViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func onClickLookForDir(_ sender: UIButton) {
        let vc = DirPreviewViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

