//
//  DirpreviewViewController.swift
//  DirpreviewViewController
//
//  Created by jinfeng on 2021/9/23.
//

import UIKit
import SnapKit


struct DirNode {
    var path: String
    var nodes: [DirNode]?
}

class DirPreviewViewController: UIViewController {

    var rootDirPath: String?
    
    let tableView = UITableView()
    
    var nodes: [DirNode] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 40;
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        
        // Do any additional setup after loading the view.
        
//        let userDirs = NSSearchPathForDirectoriesInDomains(.userDirectory, .userDomainMask, true)
//        print("userDirectory=\(userDirs)")
        
        
        
        let rootPath = rootDirPath == nil ? NSHomeDirectory() : (NSHomeDirectory() + "/" + rootDirPath!)
        DispatchQueue.global(qos: .default).async {
            if let dirs = try? FileManager.default.subpathsOfDirectory(atPath: rootPath), dirs.count > 0 {
                self.createNodes(from: dirs)
            } else {
                if let contents = try? FileManager.default.contentsOfDirectory(atPath: rootPath) {
                    self.createNodes(from: contents)
                }
            }
        }
    }
    
    func createNodes(from dirs: [String]) {
        DispatchQueue.main.async {
            for dir in dirs {
                let node = DirNode(path: dir, nodes: nil)
                self.nodes.append(node)
            }
            self.tableView.reloadData()
        }
        
    }

}


extension DirPreviewViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        nodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: "cell")
        }
        if #available(iOS 14.0, *) {
            if var c = cell?.defaultContentConfiguration() {
                c.text = nodes[indexPath.row].path
                cell?.contentConfiguration = c
            }
        } else {
            cell?.textLabel?.text = nodes[indexPath.row].path
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = DirPreviewViewController()
        vc.rootDirPath = nodes[indexPath.row].path
        self.navigationController?.pushViewController(vc
                                                      , animated: true)
    }
}
