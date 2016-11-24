//
//  ViewController.swift
//  TodaysLunch
//
//  Created by oxiden on 2016/10/30.
//  Copyright © 2016年 oxiden. All rights reserved.
//

import UIKit
import CommonFramework

class ViewController: UIViewController {
    @IBOutlet weak var viewWeb: UIWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        viewWeb.backgroundColor = UIColor.white
        let req = URLRequest(url: URL(string: Constant.URL_top)!)
        viewWeb.loadRequest(req)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

