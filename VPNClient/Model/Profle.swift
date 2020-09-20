//
//  Profile.swift
//  VPN Client
//
//  Created by Dener Araújo on 09/09/20.
//  Copyright © 2020 Dener Araújo. All rights reserved.
//

import NetworkExtension
import UIKit
import OpenVPNAdapter

/// VPN profile
public class Profile: ObservableObject {
    public let profileId = UUID().uuidString
    public var configFile: Data! = nil
    
    @Published var profileName: String
    @Published var serverAddress = ""
    @Published var username = ""
    @Published var password = ""
    @Published var customDNSEnabled = true
    @Published var dnsList = [String]()
    
    public init(profileName: String) {
        //Set profile name
        self.profileName = profileName
    }
    
    /// Load content from config file and update the profile
    /// - Parameter configFile: .ovpn file content (OpenVPN configuration file)
    public func setConfigFile(configFile: Data) {
        self.configFile = configFile
        
        let evaluation = getOVPNEvaluation()
        let dhcpOptions: [OpenVPNDhcpOptionEntry] = evaluation?.dhcpOptions ?? []
        
        serverAddress = evaluation?.remoteHost ?? ""
        username = evaluation?.username ?? ""
        dnsList = dhcpOptions.map({ $0.address ?? "" })
    }
    
    /// Parse .ovpn file
    /// - Returns: A object contating the options stored on the configuration file
    private func getOVPNEvaluation() -> OpenVPNConfigurationEvaluation? {
        do {
            let adapter = OpenVPNAdapter()
            let configuration = OpenVPNConfiguration()
            
            configuration.fileContent = configFile
            let evaluation = try adapter.apply(configuration: configuration)
            
            return evaluation
        } catch {
            return nil
        }
    }
}
