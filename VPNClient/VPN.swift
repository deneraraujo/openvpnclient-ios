//
//  VPN.swift
//  VPN Client
//
//  Created by Dener Araújo on 01/08/20.
//  Copyright © 2020 Dener Araújo. All rights reserved.
//

import NetworkExtension
import UIKit
import OpenVPNAdapter

extension NEVPNStatus: CustomStringConvertible {
    public var description: String {
        switch self {
            case .disconnected: return "disconnected"
            case .invalid: return "invalid"
            case .connected: return "connected"
            case .connecting: return "connecting"
            case .disconnecting: return "disconnecting"
            case .reasserting: return "reasserting"
        @unknown default:
            return "unknown"
        }
    }

    public var message: String {
        switch self {
            case .disconnected: return "Disconnected"
            case .invalid: return "Invalid connection attempt."
            case .connected: return "You are connected!"
            case .connecting: return "Connecting..."
            case .disconnecting: return "Disconnecting..."
            case .reasserting: return "Reconnecting..."
        @unknown default:
            return "unknown"
        }
    }
}

public class VPN: NSObject, ObservableObject {
    @Published var connectionStatus = NEVPNStatus.disconnected
    @Published var output = [Log]()
    @Published var message = Message("", .message)
    
    private var providerManager: NETunnelProviderManager! = nil
    private var isConfigSaved = false
    private let appGroupDefaults = UserDefaults(suiteName:Config.appGroupName)!
    private var evaluation: OpenVPNConfigurationEvaluation!
    private var configFile: Data! = nil
    
    public var serverAddress = ""
    public var username = ""
    public var password = ""
    public var dnsList = [String]()
    
    public enum MessageLevel {
        case error
        case success
        case alert
        case message
    }
    
    public struct Message {
        var text: String
        var level: MessageLevel
        
        init(_ text: String, _ level : MessageLevel = MessageLevel.message) {
            self.text = text
            self.level = level
        }
    }

    public override init() {
        super.init()
        
        appGroupDefaults.addObserver(self, forKeyPath: Config.logKey, options: .new, context: nil)
        Log.append("Application VPNClient started.", .debug, .mainApp)

        loadProviderManager {
            self.connectionStatus = self.providerManager.connection.status
            self.message = self.providerManager.connection.status == NEVPNStatus.disconnected ? Message("Welcome!", .message) : self.NEVPNStatusToMessage(self.providerManager.connection.status)
            
            //Register to be notified of changes in the connection status
            NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: self.providerManager.connection, queue: OperationQueue.main, using: { notification in
                self.connectionStatus = self.providerManager.connection.status
                
                Log.append("Connection status changed to \"\(self.providerManager.connection.status.description)\".", .info, .mainApp)
                self.message = self.NEVPNStatusToMessage(self.providerManager.connection.status)
            })
        }
    }
    
    private func NEVPNStatusToMessage(_ status: NEVPNStatus) -> Message {
        switch status {
        case .disconnected:
            return Message(status.message, MessageLevel.message)
        case .invalid:
            return Message(status.message, MessageLevel.error)
        case .connected:
            return Message(status.message, MessageLevel.success)
        case .connecting:
            return Message(status.message, MessageLevel.message)
        case .disconnecting:
            return Message(status.message, MessageLevel.message)
        case .reasserting:
            return Message(status.message, MessageLevel.message)
        @unknown default:
            return Message(status.message, MessageLevel.error)
        }
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let outputMessages = change?[NSKeyValueChangeKey.newKey] as? [Data] ?? [Data]()
        let qtNewMessages = outputMessages.count - output.count
        
        if qtNewMessages > 0 {
            let newMessages = outputMessages[outputMessages.count - qtNewMessages ..< outputMessages.count]

            newMessages.forEach { message in
                let log = Log.getValue(log: message)
                output.append(log)
            }
            
            //output.append(contentsOf: newMessages)
        }
    }

    private func loadProviderManager(completion:@escaping () -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
            if error == nil {
                self.providerManager = self.providerManager ?? managers?.first ?? NETunnelProviderManager()
                completion()
            } else {
                Log.append("\(error.debugDescription)", .error, .mainApp)
                self.message = Message("Error on adding VPN configuration to iOS settings.", .error)
            }
        }
    }

    private func configureAndSaveProviderManager(completion:@escaping () -> Void) {
        self.providerManager?.loadFromPreferences { error in
            if error == nil {
                let tunnelProtocol = NETunnelProviderProtocol()
                tunnelProtocol.username = self.username
                tunnelProtocol.serverAddress = self.serverAddress
                tunnelProtocol.providerBundleIdentifier = Config.packetTunnelProviderBundleId // bundle id of the network extension target
                tunnelProtocol.providerConfiguration = ["ovpn": self.configFile ?? "", "username": self.username, "password": self.password]
                tunnelProtocol.disconnectOnSleep = false

                self.providerManager.protocolConfiguration = tunnelProtocol
                self.providerManager.localizedDescription = "OpenVPN Client" // the title of the VPN profile which will appear on Settings
                self.providerManager.isEnabled = true
                
                self.appGroupDefaults.set(self.dnsList, forKey: Config.dnsListKey)

                self.providerManager.saveToPreferences(completionHandler: { (error) in
                    if error == nil  {
                        self.providerManager.loadFromPreferences(completionHandler: { (error) in
                            self.isConfigSaved = true
                            completion()
                        })
                    } else {
                        Log.append("\(error.debugDescription)", .error, .mainApp)
                        self.message = Message("Error on adding VPN configuration to iOS settings.", .error)
                    }
                })
            }
        }
    }
    
    private func startTunnel() {
        do {
            try self.providerManager.connection.startVPNTunnel()// starts the VPN tunnel.
        } catch let error {
            Log.append(error.localizedDescription, .error, .mainApp)
        }
    }
    
    public func setConfigFile(configFile: Data) {
        self.configFile = configFile
        
        let OVPNevaluation = self.getOVPNEvaluation()
        
      
        
        self.serverAddress = OVPNevaluation?.remoteHost ?? ""
        self.username = OVPNevaluation?.username ?? ""
        
    }
    
    public func startVPN() {
        if configFile == nil {
            Log.append("configFile is nil.", .debug, .mainApp)
            message = Message("Invalid configuration file.", .error)
            return
        }
        
        if username.isEmpty {
            Log.append("username is empty", .debug, .mainApp)
            message = Message("Username is empty.", .error)
            return
        }
        
        if password.isEmpty {
            Log.append("password is empty.", .debug, .mainApp)
            message = Message("Password is empty.", .error)
            return
        }

        if self.providerManager == nil {
            loadProviderManager {
                self.configureAndSaveProviderManager {
                    self.startTunnel()
                }
            }
        } else {
            self.configureAndSaveProviderManager {
                self.startTunnel()
            }
        }
    }
    
    private func getOVPNEvaluation() -> OpenVPNConfigurationEvaluation? {
        do {
            let adapter = OpenVPNAdapter()
            let configuration = OpenVPNConfiguration()
            
            configuration.fileContent = configFile
            let evaluation = try adapter.apply(configuration: configuration)
            
            //let s = evaluation.route
            
            return evaluation
        } catch {
            return nil
        }
    }
    
    public func stopVPN() {
        self.providerManager.connection.stopVPNTunnel()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        appGroupDefaults.removeObserver(self, forKeyPath: Config.logKey)
    }
}
