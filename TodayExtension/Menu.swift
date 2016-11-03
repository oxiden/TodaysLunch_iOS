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
    func retrieve(label: UILabel, date: Date) -> (Void)
    {
        // 進捗表示
        label.text = "Receiving data..."

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
                label.text = "(ERROR: URLSession#dataTask)"
            } else {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                    {
                        print(json)
                        // UILabelに表示する文字列を作成
                        self.date = date
                        self.title = (json["title"] is String ? json["title"] as! String : "メニューなし")

                        // 元のメインスレッドにて結果表示するよう、非同期で処理予約
                        DispatchQueue.main.async(execute: {
                            label.text = String(format: "%@    %@", arguments: [self.printable_release(), self.title])
                        })
                    }
                } catch {
                    print("error in JSONSerialization")
                    // 進捗表示
                    label.text = "(ERROR: JSONSerialization.jsonObject)"
                }
            }
        })
        task.resume()

        return
    }

    // self.dateを YYYY/MM/DD(@@@) 形式で返却する
    func printable_release() -> (String) {
        assert(date != nil, "Menu#date is mandatory")

        let df = DateFormatter()
        df.dateFormat = "yyyy/MM/dd"
        df.locale = NSLocale(localeIdentifier: "ja_JP") as Locale!

        return String(format: "%@(%@)", arguments: [df.string(from: self.date!), getWeekdaySymbol()])
    }

    // 指定日の曜日の短縮名(月, 火など)を取得
    private func getWeekdaySymbol() -> (String) {
        let cal: Calendar = Calendar(identifier: .gregorian)
        let comp: DateComponents = cal.dateComponents([.weekday], from: self.date!)
        let weekday: Int = comp.weekday!

        let df = DateFormatter()
        df.locale = NSLocale(localeIdentifier: "ja_JP") as Locale!
        return df.shortWeekdaySymbols[weekday - 1]
    }
}
