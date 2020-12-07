//
//  Profile.swift
//  VPN Client
//
//  Created by Dener Araújo on 09/09/20.
//  Copyright © 2020 Dener Araújo. All rights reserved.
//

import OpenVPNAdapter

/// VPN profile
public class Profile: ObservableObject, Codable {
    public var profileId: String
    public var configFile: Data! = nil

    @Published var profileName = ""
    @Published var serverAddress = ""
    @Published var username = ""
    @Published var password = ""
    @Published var customDNSEnabled = true
    @Published var dnsList = [String]()

    enum CodingKeys: CodingKey {
        case profileId
        case configFile
        case profileName
        case serverAddress
        case username
        case password
        case customDNSEnabled
        case dnsList
    }
    
    public init(profileName: String, profileId: String? = nil) {
        //Set profile name
        self.profileName = profileName
        
        //Set profile ID
        self.profileId = profileId != nil ? profileId! : UUID().uuidString
    }
    
    public init() {
        profileName = "default"
        profileId = "default"
    }
    
    required public init(from decoder:Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        profileId = try container.decode(String.self, forKey: .profileId)
        configFile = try container.decode(Data.self, forKey: .configFile)
        profileName = try container.decode(String.self, forKey: .profileName)
        serverAddress = try container.decode(String.self, forKey: .serverAddress)
        username = try container.decode(String.self, forKey: .username)
        password = try container.decode(String.self, forKey: .password)
        customDNSEnabled = try container.decode(Bool.self, forKey: .customDNSEnabled)
        dnsList = try container.decode([String].self, forKey: .dnsList)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(profileId, forKey: .profileId)
        try container.encode(configFile, forKey: .configFile)
        try container.encode(profileName, forKey: .profileName)
        try container.encode(serverAddress, forKey: .serverAddress)
        try container.encode(username, forKey: .username)
        try container.encode(password, forKey: .password)
        try container.encode(customDNSEnabled, forKey: .customDNSEnabled)
        try container.encode(dnsList, forKey: .dnsList)
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
