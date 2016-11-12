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
        // 初期表示
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
                // 元のメインスレッドにて結果表示するよう、非同期で処理予約
                DispatchQueue.main.async(execute: {
                    labelTitle.text = "(ERROR: URLSession#dataTask)"
                })
            } else {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                    {
                        // 元のメインスレッドにて結果表示するよう、非同期で処理予約
                        DispatchQueue.main.async(execute: {
                            print("Received JSON:")
                            print(json)
                            // UILabelに文字列をセット
                            self.date = date
                            self.title = (json["title"] is String ? json["title"] as! String : "メニューなし")
                            labelTitle.text = self.title
                            // 次回描画に備えてUserDefaultsでキャッシュする
                            let ud: UserDefaults = UserDefaults(suiteName: "group.TodaysLunchMenu")!
                            var udDict = ud.dictionary(forKey: "1") ?? Dictionary()
                            udDict.updateValue(self.title, forKey: Menu.storable_release(date: date))
                            ud.set(udDict, forKey: "1")
                            ud.synchronize()
                        })
                    }
                } catch {
                    print("error in JSONSerialization")
                    // 元のメインスレッドにて結果表示するよう、非同期で処理予約
                    DispatchQueue.main.async(execute: {
                        labelTitle.text = "(ERROR: JSONSerialization.jsonObject)"
                    })
                }
            }
        })
        task.resume()

        return
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

    // self.dateを YYYYMMDD 形式で返却する（UserDefaultsのDictionaryキー用）
    class func storable_release(date: Date) -> (String) {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        df.locale = NSLocale(localeIdentifier: "ja_JP") as Locale!

        return String(format: "%@", arguments: [df.string(from: date)])
    }
}
