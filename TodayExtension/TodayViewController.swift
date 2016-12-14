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

class TodayViewController: UIViewController, NCWidgetProviding, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var menu: UILabel!
    @IBOutlet weak var table: UITableView!

    var print_days = 1

    // コンストラクタ
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }

    // TableView更新用(行数)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return print_days
    }

    // TableView更新用(行ごとの更新)
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> (UITableViewCell) {
        let cell = table.dequeueReusableCell(withIdentifier: "tableCell", for: indexPath)

        let label2 = table.viewWithTag(2) as! UILabel
        label2.text = ""
        let label3 = table.viewWithTag(3) as! UILabel
        label3.text = ""
        let target_date = Calendar.current.date(byAdding: .day, value: indexPath.row, to: Date())!
        updateMenu(date: target_date, label2: label2, label3: label3)

        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row > 0 {
            cell.alpha = 0.1
            UIView.animate(withDuration: TimeInterval(0.4), animations: {
                cell.alpha = 1.0
            })
        }
    }

    // 指定日のメニューを更新し、UILabelにセットするシンタックスシュガー
    func updateMenu(date: Date, label2: UILabel, label3: UILabel) -> (Void) {
        // already hold todays' menu?
        let cached = menuCached(date: date)
        if cached != nil {
            // メニューデータ取得済み
            debugPrint("INFO: already received.(key=[\(Menu.storable_release(date: date))], value=[\(cached!)])")
            label2.text = Menu.printable_release(date: date)
            label3.text = cached!
        } else {
            // WebAPIを使用しメニューデータを取得・表示する
            Menu().retrieve(labelDate: label2, labelTitle: label3, date: date)
        }
    }

    // UserDefaultsからキャッシュデータを取得する
    private func menuCached(date: Date) -> (String?) {
        let ud: UserDefaults = UserDefaults(suiteName: Constant.APP_GROUPS_NAME)!
        let udDict = ud.dictionary(forKey: Constant.SHOP_ID) ?? Dictionary()
        let title = udDict[Menu.storable_release(date: date)] as! String?
        if title != nil {
            // メニューデータ取得済み
            debugPrint("INFO: cache found")
            return title
        } else {
            // データキャッシュなし
            debugPrint("INFO: cache not found")
            return nil
        }
    }

    // ウィジェットの再描画要否をOSに回答する
    func widgetPerformUpdate(completionHandler: @escaping ((NCUpdateResult) -> Void)) {
        debugPrint("INFO: widgetPerformUpdate")
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        completionHandler(NCUpdateResult.newData)
    }

    // ビュー追加設定
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.

        // TableViewのフックをこのコントローラでする
        table.delegate = self
        table.dataSource = self

        // "表示を増やす"を表示
        self.extensionContext?.widgetLargestAvailableDisplayMode = NCWidgetDisplayMode.expanded

        // メニュー対象
        menu.text = "夕花のランチ"

        // 初期表示
        print_days = 1
        table.reloadData()
    }

    // "表示を増やす"/"表示を減らす"選択時の処理
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        switch (activeDisplayMode) {
        case NCWidgetDisplayMode.compact:
            debugPrint("activeDisplayMode=expanded")
            // ビューの高さ変更(Compactにする)
            self.preferredContentSize = maxSize
            // 表示データ更新
            print_days = 1
        case NCWidgetDisplayMode.expanded:
            debugPrint("activeDisplayMode=expanded")
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
        }
        table.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
