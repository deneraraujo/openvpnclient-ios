//
//  Util.swift
//  VPN Client, TunnelProvider
//
//  Created by Dener Araújo on 10/08/20.
//

import Foundation

/// Useful functions
public struct Util {
    public static func getAppName() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
    }
}
