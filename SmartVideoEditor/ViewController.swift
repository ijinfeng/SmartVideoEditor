//
//  ViewController.swift
//  SmartVideoEditor
//
//  Created by JinFeng on 2021/9/20.
//

import UIKit
import FileBox

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func onClickRecord(_ sender: Any) {
        let vc = RecordViewController()
        let navi = UINavigationController(rootViewController: vc)
        navi.modalPresentationStyle = .fullScreen
        navigationController?.present(navi, animated: true, completion: nil)
    }
    
    @IBAction func onClickLookForDir(_ sender: UIButton) {
        FileBox.default.openRecently(dir: FileBox.cachePath())
    }
}

