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
    @Published var anonymousAuth = false
    @Published var username = ""
    @Published var password = ""
    @Published var customDNSEnabled = true
    @Published var dnsList = [String]()
    @Published var privKeyPassRequired = false
    @Published var privateKeyPassword = ""

    enum CodingKeys: CodingKey {
        case profileId
        case configFile
        case profileName
        case serverAddress
        case anonymousAuth
        case username
        case password
        case customDNSEnabled
        case dnsList
        case privKeyPassRequired
        case privateKeyPassword
    }
    
    public init(profileName: String, profileId: String? = nil) {
        // Set profile name
        self.profileName = profileName
        
        // Set profile ID
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
        anonymousAuth = try container.decode(Bool.self, forKey: .anonymousAuth)
        username = try container.decode(String.self, forKey: .username)
        password = try container.decode(String.self, forKey: .password)
        customDNSEnabled = try container.decode(Bool.self, forKey: .customDNSEnabled)
        dnsList = try container.decode([String].self, forKey: .dnsList)
        privKeyPassRequired = try container.decode(Bool.self, forKey: .privKeyPassRequired)
        privateKeyPassword = try container.decode(String.self, forKey: .privateKeyPassword)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(profileId, forKey: .profileId)
        try container.encode(configFile, forKey: .configFile)
        try container.encode(profileName, forKey: .profileName)
        try container.encode(serverAddress, forKey: .serverAddress)
        try container.encode(anonymousAuth, forKey: .anonymousAuth)
        try container.encode(username, forKey: .username)
        try container.encode(password, forKey: .password)
        try container.encode(customDNSEnabled, forKey: .customDNSEnabled)
        try container.encode(dnsList, forKey: .dnsList)
        try container.encode(privKeyPassRequired, forKey: .privKeyPassRequired)
        try container.encode(privateKeyPassword, forKey: .privateKeyPassword)
    }
}
