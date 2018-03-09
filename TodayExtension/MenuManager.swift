//
//  MenuManager.swift
//  TodayExtension
//
//  Created by oxiden on 2018/02/21.
//  Copyright © 2018年 oxiden. All rights reserved.
//

import Foundation
import CommonFramework
import Alamofire

class MenuManager {
    var alamofire: Alamofire.SessionManager
    var view: TodayViewController?

    // コンストラクタ
    init(_ restClient: Alamofire.SessionManager) {
        alamofire = restClient
        view = nil
    }

    // menuRetrieve()用Viewセッタ
    public func setView(_ `for`: TodayViewController) {
        view = `for`
    }

    // メニューデータを取得する(保持していなければRESTで取得し保持、保持していればキャッシュから取得)
    // update: キャッシュ無し時にデータを取り直すか
    public func get(`for`: Date, update: Bool = false) -> (Menu) {
        Logger.debug("-------------------------menuCached")
        let ud = UserDefaults(suiteName: Constant.APP_GROUPS_NAME)!
        var udDict = ud.dictionary(forKey: Constant.SHOP_ID) ?? Dictionary()
        let target_date = storable_release(date: `for`)
        let dict = udDict[target_date] as AnyObject
        let title = dict["title"] as? String
        let error = dict["error"] as? String
        let stored_at = dict["stored_at"] as? Date
        if title != nil && stored_at != nil {
            // メニューデータ取得済み
            Logger.debug("cache found")
            let debug_value = String(describing: title)
            let debug_error = String(describing: error)
            let debug_storedat = String(describing: DateUtil.JST(stored_at!))
            Logger.debug("key=\(`for`), value=\(debug_value), error=\(debug_error), stored_at=\(debug_storedat)")
            if title != "" {
                // メニューデータのTTL期間内？
                if stored_at! > Calendar.current.date(byAdding: .day, value: -Constant.CACHE_DAYS, to: Date())! {
                    return Menu(t: title!, e: error!)
                } else {
                    // キーを削除しておく
                    udDict.removeValue(forKey: target_date)
                    Logger.debug(" -> deleted.")
                    if update {
                        // 最新のデータ取得指示
                        menuRetrieve(for: `for`)
                    }
                    return Menu(t: "", e: "")
                }
            } else {
                // エラーデータのTTL期間内？
                if stored_at! > Calendar.current.date(byAdding: .minute, value: -Constant.RETRY_PERIOD_MINUTES, to: Date())! {
                    return Menu(t: title!, e: error!)
                } else {
                    if update {
                        // 最新のデータ取得指示
                        menuRetrieve(for: `for`)
                    }
                    return Menu(t: "", e: "")
                }
            }
        } else {
            // データキャッシュなし
            Logger.debug("cache not found")
            Logger.debug("key=\(`for`), value=\(String(describing: title)), error=\(String(describing: error))")
            if update {
                // 最新のデータ取得指示
                menuRetrieve(for: `for`)
            }
            return Menu(t: "", e: "")
        }
    }

    // 保持しているメニューデータを強制クリアする
    public func clear(before: Date) {
        Logger.debug("-------------------------menuCacheClear")
        let ud = UserDefaults(suiteName: Constant.APP_GROUPS_NAME)!
        var udDict = ud.dictionary(forKey: Constant.SHOP_ID) ?? Dictionary()
        let target_date = storable_release(date: before)
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
        Logger.debug("menuCacheClear done.")
    }

    // UserDefaultsにキャッシュする
    private func menuCacheStore(`for`: Date, title: String, error: String) {
        Logger.debug("-------------------------menuCacheStore")
        let ud = UserDefaults(suiteName: Constant.APP_GROUPS_NAME)!
        var udDict = ud.dictionary(forKey: Constant.SHOP_ID) ?? Dictionary()
        udDict.updateValue(["title": title, "error": error, "stored_at": Date()], forKey: storable_release(date: `for`))
        ud.set(udDict, forKey: Constant.SHOP_ID)
        Logger.debug("menuCacheStore done.")
    }

    // 指定日のメニューをRESTで取得してUserDefaultsにキャッシュする(画面にも表示する)
    private func menuRetrieve(`for`: Date) {
        Logger.debug("-------------------------menuRetrieve")
        assert(view != nil)
        // WebAPIのURL構築
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = NSLocale(localeIdentifier: "ja_JP") as Locale!
        let url = URL(string: String(format: Constant.URL, arguments: [df.string(from: `for`)]))!
        Logger.debug(url)

        // レスポンス(JSON)を取得（非同期）
        Logger.debug("set URL:\(url.debugDescription)")
        alamofire.request(url).validate().responseJSON { (response) -> Void in
            switch response.result {
            case .failure(let error):
                Logger.error("response.result.failure.")
                Logger.error(error)
                // 次回描画に備えてUserDefaultsでキャッシュする
                self.menuCacheStore(for: `for`, title: "", error: String(format: "(%@)", error.localizedDescription))
            case .success:
                // 結果表示
                if let json = response.result.value as? [String: Any] {
                    Logger.debug("Received JSON:")
                    do {
                        Logger.debug(String(data: try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted), encoding: String.Encoding.utf8) as Any)
                    } catch {
                        Logger.debug("(parse error)")
                    }
                    // UILabelに文字列をセット
                    let title = (json["title"] is String ? json["title"] as? String : "メニューなし")
                    // 次回描画に備えてUserDefaultsでキャッシュする
                    self.menuCacheStore(for: `for`, title: title!, error: "")
                } else {
                    Logger.error("response is unparsable.")
                    Logger.error(response.result.value ?? "-")
                    // 次回描画に備えてUserDefaultsでキャッシュする
                    self.menuCacheStore(for: `for`, title: "", error: "(サーバーエラー)")
                }
            }
            // 該当セルのみ更新
            self.view?.table.reloadData()
        }
    }

    // 日付を YYYYMMDD 形式で返却する（UserDefaultsのDictionaryキー用）
    private func storable_release(date: Date) -> (String) {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        df.locale = NSLocale(localeIdentifier: "ja_JP") as Locale!

        return String(format: "%@", arguments: [df.string(from: date)])
    }
}
