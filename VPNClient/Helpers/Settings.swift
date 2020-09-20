//
//  Settings.swift
//  VPNClient
//
//  Created by Dener Araújo on 18/09/20.
//

import Foundation

/// Keys for UserDefaults values
public struct Settings {
    public static let selectedProfileKey = "VPNClient_selectedProfile"
    public static let logKey = "VPNClient_log"
    
    public static func dnsListKey(profileId: String) -> String {
        return "VPNClient_\(profileId)_dnsList"
    }
}
