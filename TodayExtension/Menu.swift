//
//  Menu.swift
//  TodaysLunch
//
//  Created by oxiden on 2016/10/31.
//  Copyright © 2016年 oxiden. All rights reserved.
//

import UIKit
import NotificationCenter

class Menu: NSObject {
    var date: Date? = nil
    var title: String = "n/a"

    // WebAPIからメニューデータを取得し、指定UILabelのテキストにセットする
    func retrieve(labelDate: UILabel, labelTitle: UILabel, date: Date) -> (Void)
    {
        // 進捗表示
        labelDate.text = Menu.printable_release(date: date)
        labelTitle.text = "Receiving data..."

        // WebAPIのURL構築
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = NSLocale(localeIdentifier: "ja_JP") as Locale!
        let url = URL(string: "https://tweet-lunch-bot.herokuapp.com/shops/1/menus/" + df.string(from: date) + ".json")!

        // WebAPIからレスポンス(JSON)を取得（非同期）
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        print("set URL:" + url.debugDescription)
        let task = session.dataTask(with: url, completionHandler: {
            (data, response, error) -> (Void) in
            if error != nil {
                print(error!.localizedDescription)
                // 進捗表示
                labelTitle.text = "(ERROR: URLSession#dataTask)"
            } else {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                    {
                        print(json)
                        // UILabelに表示する文字列を作成
                        self.date = date
                        self.title = (json["title"] is String ? json["title"] as! String : "メニューなし")

                        DispatchQueue.main.async(execute: {
                            // 元のメインスレッドにて結果表示するよう、非同期で処理予約
                            labelTitle.text = self.title
                            // 次回描画に備えてApp Groupsでキャッシュする
                            let ag :UserDefaults = UserDefaults(suiteName: "group.TodaysLunchMenu")!
                            var agData = ag.dictionary(forKey: "1") as? Dictionary<String, String> ?? Dictionary<String, String>()
                            print(agData)
                            var store = Dictionary<String, String>()
                            store[Menu.storable_release(date: date)] = self.title
                            print(store)
                            // lock
                            self.synced(lock: self) {
//                                agData?[Menu.storable_release(date: date)] = self.title
                                agData.updateValue(self.title, forKey: Menu.storable_release(date: date))
                                ag.setValue(agData, forKeyPath: "1")
                                ag.synchronize()
                            }
                        })
                    }
                } catch {
                    print("error in JSONSerialization")
                    // 進捗表示
                    labelTitle.text = "(ERROR: JSONSerialization.jsonObject)"
                }
            }
        })
        task.resume()

        return
    }

    // 各URLSession#dataTask通信処理間の同期を行う
    func synced(lock: AnyObject, closure: () -> ()) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }

    // self.dateを YYYY/MM/DD(@@@) 形式で返却する（画面表示用）
    class func printable_release(date: Date) -> (String) {

        // DateFormatter
        let df = DateFormatter()
        df.dateFormat = "yyyy/MM/dd"
        df.locale = NSLocale(localeIdentifier: "ja_JP") as Locale!

        // 指定日の曜日の短縮名(月, 火など)を取得
        let cal: Calendar = Calendar(identifier: .gregorian)
        let comp: DateComponents = cal.dateComponents([.weekday], from: date)
        let weekday: Int = comp.weekday!
        let weekdaySymbol = df.shortWeekdaySymbols[weekday - 1]

        return String(format: "%@(%@)", arguments: [df.string(from: date), weekdaySymbol])
    }

    // self.dateを YYYYMMDD 形式で返却する（App GroupsのDictionaryキー用）
    class func storable_release(date: Date) -> (String) {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        df.locale = NSLocale(localeIdentifier: "ja_JP") as Locale!

        return String(format: "%@", arguments: [df.string(from: date)])
    }
}
