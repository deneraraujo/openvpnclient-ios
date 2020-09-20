//
//  PacketTunnelProvider.swift
//  Tunnel
//
//  Created by Dener Araújo on 01/08/20.
//

import NetworkExtension
import OpenVPNAdapter

/// PacketTunnelProvider extension
class PacketTunnelProvider: NEPacketTunnelProvider {
    var startHandler: ((Error?) -> Void)?
    var stopHandler: (() -> Void)?
    var vpnReachability = OpenVPNReachability()

    var configuration: OpenVPNConfiguration!
    var evaluation: OpenVPNConfigurationEvaluation!
    var UDPSession: NWUDPSession!
    var TCPConnection: NWTCPConnection!
    
    var appGroupDefaults: UserDefaults
    var profileId: String
    var dnsList = [String]()
    
    lazy var vpnAdapter: OpenVPNAdapter = {
        let adapter = OpenVPNAdapter()
        adapter.delegate = self
        return adapter
    }()
    
    override init() {
        appGroupDefaults = UserDefaults(suiteName:Config.appGroupName)!
        profileId = appGroupDefaults.value(forKey: Settings.selectedProfileKey) as! String
        
        super.init()
        
        Log.append("Application \(Util.getAppName()) started.", .debug, .packetTunnelProvider)
        dnsList = appGroupDefaults.value(forKey: Settings.dnsListKey(profileId: profileId)) as! [String]
    }
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        guard
            let protocolConfiguration = protocolConfiguration as? NETunnelProviderProtocol,
            let providerConfiguration = protocolConfiguration.providerConfiguration
            else {
                fatalError()
        }
        
        guard let ovpnFileContent: Data = providerConfiguration["ovpn"] as? Data else { return }
        
        let configuration = OpenVPNConfiguration()
        configuration.fileContent = ovpnFileContent
        
        do {
            evaluation = try vpnAdapter.apply(configuration: configuration)
        } catch {
            completionHandler(error)
            return
        }
        
        configuration.tunPersist = true

        if !evaluation.autologin {
            if let username: String = providerConfiguration["username"] as? String, let password: String = providerConfiguration["password"] as? String {
                let credentials = OpenVPNCredentials()
                credentials.username = username
                credentials.password = password
                
                do {
                    try vpnAdapter.provide(credentials: credentials)
                } catch {
                    completionHandler(error)
                    return
                }
            }
        }

        vpnReachability.startTracking { [weak self] status in
            guard status != .notReachable else { return }
            self?.vpnAdapter.reconnect(afterTimeInterval: 5)
        }

        startHandler = completionHandler
        vpnAdapter.connect(using: packetFlow)
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        guard let messageString = NSString(data: messageData, encoding: String.Encoding.utf8.rawValue) else {
            completionHandler?(nil)
            return
        }

        Log.append("Got a message from the app: \(messageString)", .info, .packetTunnelProvider)
        completionHandler?(messageData)
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    override func wake() {
    }
}

extension PacketTunnelProvider: OpenVPNAdapterDelegate {
    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, configureTunnelWithNetworkSettings networkSettings: NEPacketTunnelNetworkSettings?, completionHandler: @escaping (Error?) -> Void) {

        let DNSSettings = NEDNSSettings(servers: dnsList)
        DNSSettings.matchDomains = [""]
        
        var ipv4IncludeRoutes = [NEIPv4Route]()
        
        for dnsServerAddr in dnsList {
            let dnsRoute = NEIPv4Route(destinationAddress: dnsServerAddr, subnetMask: "255.255.255.0")
            ipv4IncludeRoutes.append(dnsRoute)
        }
        
        let ipv4Settings = networkSettings?.ipv4Settings
        ipv4Settings?.includedRoutes = ipv4IncludeRoutes
        
        let routes = ipv4Settings?.includedRoutes?.map({ return "\($0.destinationAddress) subnetmask:\($0.destinationSubnetMask)" })
        if (routes?.count ?? 0) > 0 {
            Log.append("Routes:\n\(routes?.joined(separator: "\n") ?? "")", .info, .packetTunnelProvider)
        }
        
        let remoteIPAddress = getIPAddress(dns: evaluation.remoteHost!) ?? "1.1.1.1"
        Log.append("Remote IP Address: \(remoteIPAddress)", .info, .packetTunnelProvider)
        
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: remoteIPAddress)
        settings.ipv4Settings = networkSettings?.ipv4Settings
        settings.dnsSettings = DNSSettings
        
        setTunnelNetworkSettings(settings) { (error) in
            if (networkSettings?.dnsSettings?.servers.count ?? 0) > 0 {
                Log.append("DNS servers added: \(networkSettings?.dnsSettings?.servers.joined(separator: ", ") ?? "")", .info, .packetTunnelProvider)
            }
            
            if error == nil {
                //Start handling packets
                //self.packetFlow.readPackets(completionHandler: self.handlePackets)
                //self.handlePackets()
                
                //self.readPackets(completionHandler: self.handlePackets)
                //self.packetFlow.readPackets(completionHandler: self.handlePackets)
                //self.packetFlow.readPacketObjects(completionHandler: self.handerr)
                
            } else {
                Log.append("Error: \(error.debugDescription)", .error, .packetTunnelProvider)
            }
            
            completionHandler(error)
        }
    }
    
    func getIPAddress(dns: String) -> String? {
        var success: DarwinBoolean = false
        let host = CFHostCreateWithName(nil, dns as CFString).takeRetainedValue()
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
    
    func handerr(_ packets: [NEPacket]) {
        Log.append("Packet: \(packets[0].description)", .debug, .packetTunnelProvider)
    }
    
    func handlePackets(_ packets: [Data], protocols: [NSNumber]) {
        Log.append("Packet: \(packets[0])", .debug, .packetTunnelProvider)
        
        //self.packetFlow.readPackets(completionHandler: self.handlePackets)
        
        //readPackets(completionHandler: self.handlePackets)
    }
    
    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, configureTunnelWithNetworkSettings networkSettings: NEPacketTunnelNetworkSettings?, completionHandler: @escaping (OpenVPNAdapterPacketFlow?) -> Void) {

        setTunnelNetworkSettings(networkSettings) { (error) in
            completionHandler(error == nil ? self.packetFlow : nil)
        }
    }

    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleEvent event: OpenVPNAdapterEvent, message: String?) {
        switch event {
        case .connected:
            if reasserting {
                reasserting = false
            }
            
            guard let startHandler = startHandler else { return }
            startHandler(nil)
            self.startHandler = nil
        case .disconnected:
            guard let stopHandler = stopHandler else { return }
            
            if vpnReachability.isTracking {
                vpnReachability.stopTracking()
            }
            
            stopHandler()
            self.stopHandler = nil
        case .reconnecting:
            reasserting = true
        default:
            break
        }
    }

    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleError error: Error) {
        guard let fatal = (error as NSError).userInfo[OpenVPNAdapterErrorFatalKey] as? Bool, fatal == true else {
            return
        }
        
        Log.append("\(error.localizedDescription)", .error, .packetTunnelProvider)
        Log.append("Connection Info: \(vpnAdapter.connectionInformation.debugDescription)", .info, .packetTunnelProvider)
        
        if vpnReachability.isTracking {
            vpnReachability.stopTracking()
        }

        if let startHandler = startHandler {
            startHandler(error)
            self.startHandler = nil
        } else {
            cancelTunnelWithError(error)
        }
    }

    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleLogMessage logMessage: String) {
        var logLevel: Log.LogLevel
        
        if logMessage.lowercased().contains("exception") || logMessage.lowercased().contains("error") {
            let lowMessage = logMessage.lowercased()
            
            if lowMessage.contains("tun_prop_dhcp_option_error") && dnsList.contains(where: lowMessage.contains) {
                logLevel = .debug
            } else {
                logLevel = .error
            }
        } else {
            logLevel = .info
        }
        
        Log.append(logMessage, logLevel, .packetTunnelProvider)
    }
}

extension PacketTunnelProvider: OpenVPNAdapterPacketFlow {
    func readPackets(completionHandler: @escaping (_ packets: [Data], _ procols: [NSNumber]) -> Void) {
        packetFlow.readPackets(completionHandler: completionHandler)
    }

    func writePackets(_ packets: [Data], withProtocols protocols: [NSNumber]) -> Bool {
        return packetFlow.writePackets(packets, withProtocols: protocols)
    }
}

extension NEPacketTunnelFlow: OpenVPNAdapterPacketFlow { }
