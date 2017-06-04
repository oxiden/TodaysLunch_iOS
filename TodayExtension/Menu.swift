//
//  Menu.swift
//  TodaysLunch
//
//  Created by oxiden on 2016/10/31.
//  Copyright © 2016年 oxiden. All rights reserved.
//

import UIKit
import NotificationCenter

class Menu: CustomDebugStringConvertible {
    var date: Date? = nil
    var title: String = "n/a"
    var error: String = "n/a"

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
        return "Menu(date:\(Menu.printable_release(date: self.date)) title:[\(self.title)] error:[\(self.error)]"
    }
}
