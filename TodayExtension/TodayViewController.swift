//
//  TodayViewController.swift
//  TodayExtension
//
//  Created by oxiden on 2016/10/30.
//  Copyright © 2016年 oxiden. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var menu: UILabel!
    @IBOutlet weak var table: UITableView!

    var print_days = 1

    // コンストラクタ
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
//        NotificationCenter.default.addObserver(self, selector: #selector(TodayViewController.updateMenu as (TodayViewController) -> (Date, UILabel, UILabel) -> (Void)),name: UserDefaults.didChangeNotification, object: nil)
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

    // 指定日のメニューを更新し、UILabelにセットするシンタックスシュガー
    func updateMenu(date: Date, label2: UILabel, label3: UILabel) -> (Void) {
        // already hold todays' menu?
        let cached = menuCached(date: date)
        if cached != nil {
            // メニューデータ取得済み
            print("INFO: already received.(key=[" + Menu.storable_release(date: date) + "], value=[" + cached! + "])")
            label2.text = Menu.printable_release(date: date)
            label3.text = cached!
        } else {
            // WebAPIを使用しメニューデータを取得・表示する
            Menu().retrieve(labelDate: label2, labelTitle: label3, date: date)
        }
    }

    // UserDefaultsからキャッシュデータを取得する
    private func menuCached(date: Date) -> (String?) {
        let ud: UserDefaults = UserDefaults(suiteName: "group.TodaysLunchMenu")!
        let udDict = ud.dictionary(forKey: "1") ?? Dictionary()
        let title = udDict[Menu.storable_release(date: date)] as! String?
        if title != nil {
            // メニューデータ取得済み
            //print(udDict)
            print("INFO: cache found")
            return title
        } else {
            // データキャッシュなし
            print("INFO: cache not found")
            return nil
        }
    }

    // ウィジェットの再描画要否をOSに回答する
    func widgetPerformUpdate(completionHandler: @escaping ((NCUpdateResult) -> Void)) {
        print("INFO: widgetPerformUpdate")
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
            print("activeDisplayMode=expanded")
            // ビューの高さ変更(Compactにする)
            self.preferredContentSize = maxSize
            // 表示データ更新
            print_days = 1
        case NCWidgetDisplayMode.expanded:
            print("activeDisplayMode=expanded")
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
