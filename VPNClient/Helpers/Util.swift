//
//  Util.swift
//  VPN Client, TunnelProvider
//
//  Created by Dener Araújo on 10/08/20.
//

import Foundation

/// Useful functions
public struct Util {
    /// Get current application (or extension) name
    public static func getAppName() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
    }
    
    
    /// Get string from localizable.strings file, and format if necessary
    /// - Returns: translated string
    public static func localize(_ key: String, _ arguments: CVarArg...) -> String {
        var response: String
        
        if (arguments.count > 0) {
            response = String(format: NSLocalizedString(key, comment: key), arguments: arguments)
        } else {
            response = NSLocalizedString(key, comment: key)
        }
        
        return response
    }
}
