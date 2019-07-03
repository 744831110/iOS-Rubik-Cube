//
//  ViewController.swift
//  magicCude
//
//  Created by 陈谦 on 2019/6/25.
//  Copyright © 2019 陈谦. All rights reserved.
//

import Foundation
import UIKit
class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let button = UIButton()
        button.setTitle("点击进入魔方", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(clickButton), for: .touchUpInside)
        button.frame = CGRect(x: 50, y: 50, width: 150, height: 50)
        view.addSubview(button)
    }
    
    @objc func clickButton() {
        self.present(MagicCubeViewController(), animated: true, completion: nil)
    }
    
}


