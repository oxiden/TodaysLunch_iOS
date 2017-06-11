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

    // コンストラクタ
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
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
        let label2 = table.viewWithTag(2) as! UILabel
        let label3 = table.viewWithTag(3) as! UILabel

        // 指定日のメニューを更新し、UILabelにセットする
        let target_date = Calendar.current.date(byAdding: .day, value: indexPath.row, to: Date())!
        let result = menuCached(for: target_date, update: true)
        label2.text = Menu.printable_release(date: target_date)
        label3.text = (result.title != "") ? result.title : (result.error != "" ? result.error : "Receiving data...")

        return cell
    }

    // TableView更新用(フェードイン効果)
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row > 0 {
            cell.alpha = 0.1
            UIView.animate(withDuration: TimeInterval(0.4), animations: {
                cell.alpha = 1.0
            })
        }
    }

    // UserDefaultsからキャッシュデータを取得する
    private func menuCached(`for`: Date, update: Bool = false) -> (title: String, error: String) {
        Logger.debug("-------------------------menuCached")
        let ud = UserDefaults(suiteName: Constant.APP_GROUPS_NAME)!
        var udDict = ud.dictionary(forKey: Constant.SHOP_ID) ?? Dictionary()
        let target_date = Menu.storable_release(date: `for`)
        let dict = udDict[target_date] as AnyObject
        let title = dict["title"] as? String
        let error = dict["error"] as? String
        if title != nil {
            // メニューデータ取得済み
            Logger.debug("cache found")
            let stored_at = dict["stored_at"] as! Date
            Logger.debug("key=\(`for`), value=\(String(describing: title)), error=\(String(describing: error)), stored_at=\(String(describing: JST(stored_at)))")
            // メニューデータのTTL期間内？
            if stored_at > Calendar.current.date(byAdding: .day, value: -Constant.CACHE_DAYS, to: Date())! {
                return (title!, error!)
            } else {
                // キーを削除しておく
                udDict.removeValue(forKey: target_date)
                Logger.debug(" -> deleted.")
                ud.set(udDict, forKey: Constant.SHOP_ID)
                ud.synchronize()
                if update {
                    // 最新のデータ取得指示
                    menuRetrieve(for: `for`)
                }
                return ("", "")
            }
        } else {
            // データキャッシュなし
            Logger.debug("cache not found")
            if update {
                // 最新のデータ取得指示
                menuRetrieve(for: `for`)
            }
            return ("", "")
        }
    }

    // UserDefaultsにキャッシュする
    private func menuCacheStore(`for`: Date, title: String, error: String) -> (Void) {
        Logger.debug("-------------------------menuCacheStore")
        let ud = UserDefaults(suiteName: Constant.APP_GROUPS_NAME)!
        var udDict = ud.dictionary(forKey: Constant.SHOP_ID) ?? Dictionary()
        udDict.updateValue(["title": title, "error": error, "stored_at": Date()], forKey: Menu.storable_release(date: `for`))
        ud.set(udDict, forKey: Constant.SHOP_ID)
        ud.synchronize()
        Logger.debug("menuCacheStore done.")
    }

    // UserDefaultsのキャッシュデータをクリアする
    private func menuCacheClear(`for`: Date) -> (Void) {
        Logger.debug("-------------------------menuCacheClear")
        let ud = UserDefaults(suiteName: Constant.APP_GROUPS_NAME)!
        var udDict = ud.dictionary(forKey: Constant.SHOP_ID) ?? Dictionary()
        let target_date = Menu.storable_release(date: `for`)
        for menu in udDict.keys {
            let dict = udDict[menu] as AnyObject
            let title = dict["title"] as? String ?? "n/a"
            let error = dict["error"] as? String ?? "n/a"
            Logger.debug("key=\(menu), value=\(String(describing: title)), error=\(String(describing: error)))")
            if target_date > menu {
                udDict.removeValue(forKey: menu)
                Logger.debug(" -> deleted.")
            }
        }
        ud.set(udDict, forKey: Constant.SHOP_ID)
        ud.synchronize()
        Logger.debug("menuCacheClear done.")
    }

    // 指定日のメニューを取得して画面に表示し、キャッシュをUserDefaultsに保存する
    private func menuRetrieve(`for`: Date) -> (Void) {
        Logger.debug("-------------------------menuRetrieve")
        // WebAPIのURL構築
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = NSLocale(localeIdentifier: "ja_JP") as Locale!
        let url = URL(string: String(format: Constant.URL, arguments: [df.string(from: `for`)]))!
        Logger.debug(url)

        // レスポンス(JSON)を取得（非同期）
        Logger.debug("set URL:\(url.debugDescription)")
        Alamofire.request(url).validate().responseJSON {
            (response) -> (Void) in
            switch response.result {
            case .failure(let error):
                Logger.error("response.result.failure.")
                Logger.error(error)
                // 次回描画に備えてUserDefaultsでキャッシュする
                self.menuCacheStore(for: `for`, title: "", error: String(describing: error))
            case .success:
                // 結果表示
                if let json = response.result.value as? [String: Any] {
                    Logger.debug("Received JSON:")
                    Logger.debug(String(data: try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted), encoding: String.Encoding.utf8) as Any)
                    // UILabelに文字列をセット
                    let title = (json["title"] is String ? json["title"] as! String : "メニューなし")
                    // 次回描画に備えてUserDefaultsでキャッシュする
                    self.menuCacheStore(for: `for`, title: title, error: "")
                } else {
                    Logger.error("response is unparsable.")
                    Logger.error(response.result.value ?? "-")
                    // 次回描画に備えてUserDefaultsでキャッシュする
                    self.menuCacheStore(for: `for`, title: "", error: String(describing: "サーバーエラー"))
                }
            }
            // 該当セルのみ更新 ※self.table.reloadData()はチラつくので使用しない
            let index = self.dateDifference(from: Date(), to: `for`)
            let row = NSIndexPath(row: index, section: 0)
            self.table.reloadRows(at: [row as IndexPath], with: UITableViewRowAnimation.fade)
        }

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
        switch (activeDisplayMode) {
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
        }
        table.reloadData()
    }

    // ビューが画面に表示される前の処理
    override func viewWillAppear(_ animated: Bool) {
        Logger.debug("=========================================viewWillAppear")

        // メニューデータキャッシュをクリアする
        menuCacheClear(for: Date())
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

    // 2つの日付の日数差を返す
    private func dateDifference(from: Date, to: Date) -> (Int) {
        let dateFrom = Calendar.current.dateComponents([.year, .month, .day], from: from)
        let dateTo = Calendar.current.dateComponents([.year, .month, .day], from: to)
        return Calendar.current.dateComponents([.day], from: dateFrom, to: dateTo).day!
    }

    // Dateをローカルタイムゾーンで返す
    private func JST(_ date: Date)-> (Date) {
        let df = DateFormatter()
        df.dateFormat = "yyyy/MM/dd HH:mm:ss Z"
        df.timeZone = NSTimeZone.default
        return df.date(from: df.string(from: date))!
    }
}
