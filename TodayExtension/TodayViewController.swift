//
//  TodayViewController.swift
//  TodayExtension
//
//  Created by oxiden on 2016/10/30.
//  Copyright © 2016年 oxiden. All rights reserved.
//

import UIKit
import NotificationCenter
import CommonFramework
import Alamofire

class TodayViewController: UIViewController, NCWidgetProviding, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var menu: UILabel!
    @IBOutlet weak var table: UITableView!

    // 表示する件数
    var print_days = 1
    // メニューマネージャ
    var rest: MenuManager

    // コンストラクタ
    required init(coder aDecoder: NSCoder) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = TimeInterval(Constant.REST_TIMEOUT)
        let alamofire = Alamofire.SessionManager(configuration: configuration)
        rest = MenuManager(alamofire)

        super.init(coder: aDecoder)!

        rest.setView(self)
    }

    // TableView更新用(行数)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Logger.debug("---------------------------------tableView(numberOfRowsInSection)")
        return print_days
    }

    // TableView更新用(行ごとの更新)
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> (UITableViewCell) {
        Logger.debug("---------------------------------tableView(IndexPath)")
        let cell = table.dequeueReusableCell(withIdentifier: "tableCell", for: indexPath)
        let label2 = table.viewWithTag(2) as? UILabel
        let label3 = table.viewWithTag(3) as? UILabel

        // 指定日のメニューを更新し、UILabelにセットする
        let target_date = Calendar.current.date(byAdding: .day, value: indexPath.row, to: Date())!
        let result = rest.get(for: target_date, update: true)
        label2?.text = DateUtil.printable_release(date: target_date)
        label3?.text = (result.title != "") ? result.title : (result.error != "" ? result.error : "Receiving data...")

        return cell
    }

    // ウィジェットの再描画要否をOSに回答する
    func widgetPerformUpdate(completionHandler: @escaping ((NCUpdateResult) -> Void)) {
        Logger.debug("=========================================widgetPerformUpdate")
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        completionHandler(NCUpdateResult.noData)
    }

    // ビュー追加設定
    override func viewDidLoad() {
        Logger.debug("=========================================viewDidLoad")
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.

        // TableViewのフックをこのコントローラでする
        table.delegate = self
        table.dataSource = self

        // "表示を増やす"を表示
        self.extensionContext?.widgetLargestAvailableDisplayMode = NCWidgetDisplayMode.expanded

        // メニュー対象
        menu.text = Constant.SHOP_TITLE

        // 初期表示
        print_days = 1
    }

    // "表示を増やす"/"表示を減らす"選択時の処理
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        Logger.debug("---------------------------------widgetActiveDisplayModeDidChange")
        switch activeDisplayMode {
        case NCWidgetDisplayMode.compact:
            Logger.debug("activeDisplayMode=expanded")
            // ビューの高さ変更(Compactにする)
            self.preferredContentSize = maxSize
            // 表示データ更新
            print_days = 1
        case NCWidgetDisplayMode.expanded:
            Logger.debug("activeDisplayMode=expanded")
            var widgetHeight = maxSize.height
            if widgetHeight < 230 {
                // ビューの高さ変更(中にする)
                widgetHeight = 175
                // 表示データ更新
                print_days = 3
            } else {
                // ビューの高さ変更(最大にする)
                widgetHeight = 340
                // 表示データ更新
                print_days = 7
            }
            self.preferredContentSize = CGSize(width: 0, height: widgetHeight)
        @unknown default:
            print_days = 0
        }
        table.reloadData()
    }

    // ビューが画面に表示される前の処理
    override func viewWillAppear(_ animated: Bool) {
        Logger.debug("=========================================viewWillAppear")

        // メニューデータキャッシュをクリアする
        rest.clear(before: Date())
    }

    // ビューが画面に完全に表示された時の処理
    override func viewDidAppear(_ animated: Bool) {
        Logger.debug("=========================================viewDidAppear")
    }

    override func didReceiveMemoryWarning() {
        Logger.debug("=========================================didReceiveMemoryWarning")
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
