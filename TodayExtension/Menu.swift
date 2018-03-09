//
//  Menu.swift
//  TodaysLunch
//
//  Created by oxiden on 2016/10/31.
//  Copyright © 2016年 oxiden. All rights reserved.
//

import UIKit
import NotificationCenter
import CommonFramework

class Menu: CustomDebugStringConvertible {
    var date: Date?
    var title: String = "n/a"
    var error: String = "n/a"

    // コンストラクタ
    init(t: String, e: String) {
        title = t
        error = e
    }

    // CustomDebugString
    var debugDescription: String {
        return "Menu(date:\(DateUtil.printable_release(date: self.date)) title:[\(self.title)] error:[\(self.error)]"
    }
}
