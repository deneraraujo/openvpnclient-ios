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
    /// - Returns: Translated string
    public static func localize(_ key: String, _ arguments: CVarArg...) -> String {
        var response: String
        
        if (arguments.count > 0) {
            response = String(format: NSLocalizedString(key, comment: key), arguments: arguments)
        } else {
            response = NSLocalizedString(key, comment: key)
        }
        
        return response
    }
    
    /// Get IP Address from a DNS
    /// - Parameter hostname: Host name or DNS
    /// - Returns: IP Address
    public static func getIPAddress(_ hostname: String) -> String? {
        var success: DarwinBoolean = false
        let host = CFHostCreateWithName(nil, hostname as CFString).takeRetainedValue()
        CFHostStartInfoResolution(host, .addresses, nil)
        
        if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray?,
            let theAddress = addresses.firstObject as? NSData {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            
            if getnameinfo(theAddress.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(theAddress.length),
                           &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                let numAddress = String(cString: hostname)
                
                return numAddress
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}
