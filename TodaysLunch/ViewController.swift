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
    let ctlRefresh: UIRefreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        viewWeb.backgroundColor = UIColor.white
        let req = URLRequest(url: URL(string: Constant.URL_top)!)
        viewWeb.loadRequest(req)

        // pull to refresh WebView
//        ctlRefresh.attributedTitle = NSAttributedString(string: "reloading...")
        ctlRefresh.addTarget(self, action: #selector(ViewController.viewReload), for: .valueChanged)
        viewWeb.scrollView.addSubview(ctlRefresh)
    }

    func viewReload() {
        ctlRefresh.endRefreshing()
        viewWeb.reload()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

