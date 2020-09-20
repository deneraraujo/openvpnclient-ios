//
//  Connection.swift
//  VPNClient
//
//  Created by Dener Araújo on 01/08/20.
//

import NetworkExtension
import UIKit
import OpenVPNAdapter

/// Manage VPN connection
public class Connection: NSObject, ObservableObject {
    private var providerManager: NETunnelProviderManager! = nil
    private var isConfigSaved = false
    private var evaluation: OpenVPNConfigurationEvaluation!
    private var appGroupDefaults: UserDefaults
    private var profile: Profile
    
    @Published var connectionStatus = NEVPNStatus.disconnected
    @Published var output = [Log]()
    @Published var message = Message("", .message)
    
    public init(profile: Profile) {
        //Load user defaults
        appGroupDefaults = UserDefaults(suiteName: Config.appGroupName)!
        
        //Set active profile
        self.profile = profile
        
        super.init()
        
        //Set current profile as selected in UserDefaults
        appGroupDefaults.set(self.profile.profileId, forKey: Settings.selectedProfileKey)
        
        //Add observer to Log output
        appGroupDefaults.addObserver(self, forKeyPath: Settings.logKey, options: .new, context: nil)
        
        //First Log output
        Log.append("Application \(Util.getAppName()) started.", .debug, .mainApp)
        
        //Load iOS VPN settings manager and get our connection current status
        loadProviderManager {
            self.connectionStatus = self.providerManager.connection.status
            
            //First message output: our connection status
            //"Welcome" if the connection was not already established in a previous instance of this app
            self.message = self.providerManager.connection.status == NEVPNStatus.disconnected ? Message("Welcome!", .message) : self.NEVPNStatusToMessage(self.providerManager.connection.status)
            
            //Register to be notified of changes in the connection status
            NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: self.providerManager.connection, queue: OperationQueue.main, using: { notification in
                self.connectionStatus = self.providerManager.connection.status
                
                Log.append("Connection status changed to \"\(self.providerManager.connection.status.description)\".", .info, .mainApp)
                self.message = self.NEVPNStatusToMessage(self.providerManager.connection.status)
            })
        }
    }
    
    /// Get VPN settings profiles from iOS
    /// - Parameter completion: Callback function
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
    
    /// Convert NEVPNStatus to Message structure
    /// - Parameter status: the NEVPNStatus (connection status)
    /// - Returns: Message structure for view presentation purpose
    private func NEVPNStatusToMessage(_ status: NEVPNStatus) -> Message {
        switch status {
        case .disconnected:
            return Message(status.message, .message)
        case .invalid:
            return Message(status.message, .error)
        case .connected:
            return Message(status.message, .success)
        case .connecting:
            return Message(status.message, .message)
        case .disconnecting:
            return Message(status.message, .message)
        case .reasserting:
            return Message(status.message, .message)
        @unknown default:
            return Message(status.message, .error)
        }
    }
    
    /// Observe new Log entries in UserDefaults and append to "output" variable
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let outputMessages = change?[NSKeyValueChangeKey.newKey] as? [Data] ?? [Data]()
        let qtNewMessages = outputMessages.count - output.count
        
        if qtNewMessages > 0 {
            let newMessages = outputMessages[outputMessages.count - qtNewMessages ..< outputMessages.count]
            
            //Append each new log entry
            newMessages.forEach { message in
                let log = Log.getValue(data: message)
                output.append(log)
                NSLog(log.text)
            }
            
            //Append all new log entries in batch
            //output.append(contentsOf: newMessages)
        }
    }
    
    /// Create or update a VPN setting and add to iOS profiles
    /// - Parameter completion: Callback function
    private func configureAndSaveProviderManager(completion:@escaping () -> Void) {
        self.providerManager?.loadFromPreferences { error in
            if error == nil {
                let tunnelProtocol = NETunnelProviderProtocol()
                tunnelProtocol.username = self.profile.username
                tunnelProtocol.serverAddress = self.profile.serverAddress
                tunnelProtocol.providerBundleIdentifier = Config.packetTunnelProviderBundleId // bundle id of the network extension target
                tunnelProtocol.providerConfiguration = ["ovpn": self.profile.configFile ?? "", "username": self.profile.username, "password": self.profile.password]
                tunnelProtocol.disconnectOnSleep = false

                self.providerManager.protocolConfiguration = tunnelProtocol
                self.providerManager.localizedDescription = "\(Util.getAppName()) (\(self.profile.profileName))" // the title of the VPN profile which will appear on Settings
                self.providerManager.isEnabled = true
                
                self.appGroupDefaults.set(self.profile.dnsList, forKey: Settings.dnsListKey(profileId: self.profile.profileId))

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
    
    /// Validate profile entries an starts (or not) the connection
    public func startVPN() {
        if profile.configFile == nil {
            Log.append("configFile is nil.", .debug, .mainApp)
            message = Message("Invalid configuration file.", .error)
            return
        }
        
        if profile.username.isEmpty {
            Log.append("username is empty", .debug, .mainApp)
            message = Message("Username is empty.", .error)
            return
        }
        
        if profile.password.isEmpty {
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
    
    /// Start the connection
    private func startTunnel() {
        do {
            try self.providerManager.connection.startVPNTunnel()// starts the VPN tunnel.
        } catch let error {
            Log.append(error.localizedDescription, .error, .mainApp)
        }
    }
    
    /// Interrupt the connection
    public func stopVPN() {
        self.providerManager.connection.stopVPNTunnel()
    }
    
    /// Dipose observers
    deinit {
        NotificationCenter.default.removeObserver(self)
        appGroupDefaults.removeObserver(self, forKeyPath: Settings.logKey)
    }
}

/// Set string representation and friendly messages to NEVPNStatus (connection status)
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
