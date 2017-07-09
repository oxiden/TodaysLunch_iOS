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

    // コンストラクタ
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }

    // ビュー追加設定
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
        // WebViewのリロード
        ctlRefresh.endRefreshing()
        viewWeb.reload()
        Logger.debug("reloaded.")
        // UserDefaultsのデータをクリア
        let ud = UserDefaults(suiteName: Constant.APP_GROUPS_NAME)!
        var udDict = ud.dictionary(forKey: Constant.SHOP_ID) ?? Dictionary()
        udDict.removeAll()
        ud.set(udDict, forKey: Constant.SHOP_ID)
        ud.synchronize()
        Logger.debug("cleared.")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
