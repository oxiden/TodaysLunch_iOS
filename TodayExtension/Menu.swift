//
//  Menu.swift
//  TodaysLunch
//
//  Created by oxiden on 2016/10/31.
//  Copyright © 2016年 oxiden. All rights reserved.
//

import UIKit
import NotificationCenter
import Alamofire
import CommonFramework

class Menu: CustomDebugStringConvertible {
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
        let url = URL(string: String(format: Constant.URL, arguments: [df.string(from: date)]))!
        Logger.debug(url)

        // レスポンス(JSON)を取得（非同期）
        Logger.debug("set URL:\(url.debugDescription)")
        Alamofire.request(url).validate().responseJSON {
            (response) -> (Void) in
            switch response.result {
            case .failure(let error):
                Logger.error("response.result.failure.")
                Logger.error(error)
                // 結果表示Any
                labelTitle.text = "(ERROR: \(error))"
            case .success:
                // 結果表示
                if let json = response.result.value as? [String: Any] {
                    Logger.debug("Received JSON:")
                    Logger.debug(json)
                    // UILabelに文字列をセット
                    self.date = date
                    self.title = (json["title"] is String ? json["title"] as! String : "メニューなし")
                    labelTitle.text = self.title
                    // 次回描画に備えてUserDefaultsでキャッシュする
                    let ud = UserDefaults(suiteName: Constant.APP_GROUPS_NAME)!
                    var udDict = ud.dictionary(forKey: Constant.SHOP_ID) ?? Dictionary()
                    udDict.updateValue(self.title, forKey: Menu.storable_release(date: date))
                    ud.set(udDict, forKey: Constant.SHOP_ID)
                    ud.synchronize()
                } else {
                    Logger.error("response is unparsable.")
                    Logger.error(response.result.value ?? "-")
                    // 結果表示
                    labelTitle.text = "(ERROR: サーバーエラー)"
                }
            }
        }

        return
    }

    // self.dateを YYYY/MM/DD(@@@) 形式で返却する（画面表示用）
    class func printable_release(date: Date?) -> (String) {
        guard let target = date else {
            return "0000/00/00(--)"
        }

        // DateFormatter
        let df = DateFormatter()
        df.dateFormat = "yyyy/MM/dd"
        df.locale = NSLocale(localeIdentifier: "ja_JP") as Locale!

        // 指定日の曜日の短縮名(月, 火など)を取得
        let cal: Calendar = Calendar(identifier: .gregorian)
        let comp: DateComponents = cal.dateComponents([.weekday], from: target)
        let weekday: Int = comp.weekday!
        let weekdaySymbol = df.shortWeekdaySymbols[weekday - 1]

        return String(format: "%@(%@)", arguments: [df.string(from: target), weekdaySymbol])
    }

    // self.dateを YYYYMMDD 形式で返却する（UserDefaultsのDictionaryキー用）
    class func storable_release(date: Date) -> (String) {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        df.locale = NSLocale(localeIdentifier: "ja_JP") as Locale!

        return String(format: "%@", arguments: [df.string(from: date)])
    }

    // CustomDebugString
    var debugDescription: String {
        return "Menu(date:\(Menu.printable_release(date: self.date)) title:[\(self.title)]"
    }
}
