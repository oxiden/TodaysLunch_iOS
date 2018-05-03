//
//  DateUtil.swift
//  CommonFramework
//
//  Created by oxiden on 2018/02/21.
//  Copyright © 2018年 oxiden. All rights reserved.
//

import Foundation

public class DateUtil {
    // 日付を YYYY/MM/DD(@@@) 形式で返却する（画面表示用）
    public class func printable_release(date: Date?) -> (String) {
        guard let target = date else {
            return "0000/00/00(--)"
        }

        // DateFormatter
        let df = DateFormatter()
        df.dateFormat = "yyyy/MM/dd"
        df.locale = NSLocale(localeIdentifier: "ja_JP") as Locale?

        // 指定日の曜日の短縮名(月, 火など)を取得
        let cal: Calendar = Calendar(identifier: .gregorian)
        let comp: DateComponents = cal.dateComponents([.weekday], from: target)
        let weekday: Int = comp.weekday!
        let weekdaySymbol = df.shortWeekdaySymbols[weekday - 1]

        return String(format: "%@(%@)", arguments: [df.string(from: target), weekdaySymbol])
    }

    // 2つの日付の日数差を返す
    public class func dateDifference(from: Date, to: Date) -> (Int) {
        let dateFrom = Calendar.current.dateComponents([.year, .month, .day], from: from)
        let dateTo = Calendar.current.dateComponents([.year, .month, .day], from: to)
        return Calendar.current.dateComponents([.day], from: dateFrom, to: dateTo).day!
    }

    // Dateをローカルタイムゾーンで返す
    public class func JST(_ date: Date) -> (Date) {
        let df = DateFormatter()
        df.dateFormat = "yyyy/MM/dd HH:mm:ss Z"
        df.timeZone = NSTimeZone.default
        return df.date(from: df.string(from: date))!
    }
}
