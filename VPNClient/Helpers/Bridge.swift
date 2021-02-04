//
//  Bridge.swift
//  VPNClient
//
//  Created by Dener Araújo on 03/02/21.
//

import Foundation

/// Read/write values on UserDefaults for cross-target (main app and extension app) communcation purpose
public struct Bridge {
    public static let BRIDGE_KEY = "vpnclient_bridge"
    private static let jsonEncoder = JSONEncoder()
    private static let jsonDecoder = JSONDecoder()
    private static let appGroupDefaults = UserDefaults(suiteName:Config.appGroupName)!
    
    /// Write a value on UserDefaults under "bridge" prefix
    public static func set(key: String, value: String) {
        let tuple = Tuple(key: key, value: value)
        
        do {
            var tuples = get()
            tuples.append(tuple)
            
            let encodedData = try jsonEncoder.encode(tuples)
            appGroupDefaults.set(encodedData, forKey: BRIDGE_KEY)
        } catch {
            NSLog(error.localizedDescription)
        }
    }
    
    /// Get a value from UserDefaults by key under "bridge" prefix
    public static func get(key: String) -> String? {
        let tuples = get()
        return findValue(tuples: tuples, key: key)
    }
    
    /// Get a value from a array of Data under "bridge" prefix
    public static func get(data: Data, key: String) -> String? {
        let tuples = getValues(data: data)
        return findValue(tuples: tuples, key: key)
    }
    
    /// Get all values from UserDefaults under "bridge" prefix
    public static func get() -> [Tuple] {
        let bridge_data = appGroupDefaults.value(forKey: BRIDGE_KEY) as? Data ?? nil
        let values = bridge_data != nil ? getValues(data: bridge_data!) : []
        
        return values
    }
    
    /// Parse data
    private static func getValues(data: Data) -> [Tuple] {
        var value: [Tuple]
        
        do {
            value = try jsonDecoder.decode([Tuple].self, from: data)
        } catch {
            value = []
            NSLog(error.localizedDescription)
        }
        
        return value
    }
    
    /// Find a single value in all values under "bridge" prefix
    private static func findValue(tuples: [Tuple], key: String) -> String? {
        var value: String?
        
        if let tuple = tuples.last(where: {$0.key == key}) {
            value = tuple.value
        } else {
            value = nil
        }
        
        return value
    }
    
    /// Clean all entries stored on UserDefaults under "bridge" prefix
    public static func clean() {
        appGroupDefaults.removeObject(forKey: BRIDGE_KEY)
    }

    public struct Tuple: Codable {
        public var key: String
        public var value: String
    }
}
