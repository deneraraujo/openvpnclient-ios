//
//  Log.swift
//  TunnelProvider
//
//  Created by Dener Araújo on 07/08/20.
//

import Foundation

/// Cross-target Log (stored in UserDefaults)
public struct Log: Codable, Hashable {
    public static let LOG_KEY = "vpnclient_log"
    
    private var id: String
    public var text: String
    public var level: LogLevel
    public var source: LogSource
    
    private static let jsonEncoder = JSONEncoder()
    private static let jsonDecoder = JSONDecoder()
    private static let appGroupDefaults = UserDefaults(suiteName:Config.appGroupName)!
    private static var df: DateFormatter? = nil
    
    enum CodingKeys: CodingKey {
        case id
        case text
        case level
        case source
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(text)
        hasher.combine(level)
        hasher.combine(source)
    }
    
    init(text: String, level: LogLevel, source: LogSource) {
        if Log.df == nil {
            Log.df = DateFormatter()
            Log.df!.dateFormat = "yyyyMMddHHmmss.SSSS"
        }
        
        self.id = Log.df!.string(from: Date())
        self.text = text
        self.level = level
        self.source = source
    }

    init(json: [String: Any])
    {
        self.id = (json["id"] as? String) ?? ""
        self.text = (json["text"] as? String) ?? ""
        self.level = LogLevel(rawValue: json["level"] as! Int)!
        self.source = LogSource(rawValue: json["source"] as! Int)!
    }
    
    public enum LogLevel : Int, Codable {
        case debug
        case info
        case notice
        case warning
        case error
        case critical
        case alert
        case emergency
    }
    
    public enum LogSource : Int, Codable {
        case mainApp
        case packetTunnelProvider
        case other
    }
    
    public static func append(_ logText: String, _ logLevel: LogLevel = .info, _ logSource: LogSource) {
        let log = Log(text: logText.trimmingCharacters(in: .whitespacesAndNewlines),
                      level: logLevel,
                      source: logSource)

        append(log)
    }

    public static func append(_ log: Log) {
        //NSLog(log.text)
        var outputMessages = (appGroupDefaults.value(forKey: LOG_KEY) as? [Data]) ?? []
        
        do {
            let encodedData = try jsonEncoder.encode(log)
            outputMessages.append(encodedData)

            appGroupDefaults.set(outputMessages, forKey: LOG_KEY)
        } catch {
            NSLog(error.localizedDescription)
        }
    }
    
    public static func getValues() -> [Log] {
        var values = [Log]()
        let logs = appGroupDefaults.value(forKey: LOG_KEY) as! [Data]
        
        logs.forEach { log in
            let value = getValue(data: log)
            values.append(value)
        }
        
        return values
    }
    
    public static func getValue(data: Data) -> Log {
        var value: Log
        
        do {
            value = try jsonDecoder.decode(Log.self, from: data)
        } catch {
            value = Log(text: "Error on deserialize log data from UserDefaults: \(error.localizedDescription)", level: .debug, source: .other)
            NSLog(error.localizedDescription)
        }
        
        return value
    }

    public static func clean() {
        appGroupDefaults.removeObject(forKey: LOG_KEY)
    }
}
