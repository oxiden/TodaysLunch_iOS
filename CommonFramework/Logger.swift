//
//  Logger.swift
//  TodaysLunch
//
//  Created by oxiden on 2017/01/02.
//  Copyright © 2017年 oxiden. All rights reserved.
//

import Foundation
import os.log

public class Logger {

    static public func debug(_ format: Any, params: CVarArg...) {
        _writelog(format, oslogType: .debug, args: params)
    }
    static public func error(_ format: Any, params: CVarArg...) {
        _writelog(format, oslogType: .error, args: params)
    }
    static public func fatal(_ format: Any, params: CVarArg...) {
        _writelog(format, oslogType: .fault, args: params)
    }
    static public func info(_ format: Any, params: CVarArg...) {
        _writelog(format, oslogType: .info, args: params)
    }

    static private func _writelog(_ format: Any, oslogType: OSLogType, args: CVarArg...) {
        var level: String {
            switch (oslogType) {
            case OSLogType.debug:
                return "DEBUG"
            case OSLogType.default:
                return "DEFAULT"
            case OSLogType.error:
                return "ERROR"
            case OSLogType.fault:
                return "FATAL"
            case OSLogType.info:
                return "INFO"
            default:
                return "DEFAULT"
            }
        }
        let oslog = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: level)
        os_log("%@", log: oslog, type: oslogType, String(format: (format as! NSObject).description))
    }

}
