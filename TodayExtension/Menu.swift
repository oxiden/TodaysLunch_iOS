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

    public enum RetrieveMenuError: Error {
        case notConvertible(Any?)
        case JSONSerialization
    }

    func update(date: Date, title: String) -> (Menu)
    {
        self.date = date
        self.title = title
        return self
    }

    func retrieve(label: UILabel, date: Date) -> (NCUpdateResult)
    {
        // build url
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = NSLocale(localeIdentifier: "ja_JP") as Locale!
        let url = URL(string: "https://tweet-lunch-bot.herokuapp.com/shops/1/menus/" + df.string(from: date) + ".json")!

        // get REST response
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        print("set URL:" + url.debugDescription)
        let task = session.dataTask(with: url, completionHandler: {
            (data, response, error) -> Void in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                    {
                        // prepare menu
                        print(json)
                        let menuTitle: String = (json["title"] is String ? json["title"] as! String : "メニューなし")

                        // result
                        self.update(date: date, title: menuTitle)

                        // print result via main thread
                        DispatchQueue.main.async(execute: {
                            label.text = String(format: "%@    %@", arguments: [self.printable_release(), self.title])
                        })
                    }
                    ////return NCUpdateResult.newData
                } catch {
                    print("error in JSONSerialization")
                    //throw RetrieveMenuError.JSONSerialization("error in JSONSerialization")
                }
            }
        })
        task.resume()

        return NCUpdateResult.noData
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
