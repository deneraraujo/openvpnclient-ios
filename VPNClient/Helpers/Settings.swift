//
//  Settings.swift
//  VPNClient
//
//  Created by Dener Araújo on 18/09/20.
//

import Foundation

/// Structure to store app settings on UserDefaults
public struct Settings: Codable {
    private static let SETTINGS_KEY = "vpnclient_settings"
    
    private static var _selectedProfileId: String = ""
    private static var _profiles: [Profile] = []

    private var selectedProfileId: String
    private var profiles: [Profile]
    
    private static let jsonEncoder = JSONEncoder()
    private static let jsonDecoder = JSONDecoder()
    private static let appGroupDefaults = UserDefaults(suiteName:Config.appGroupName)!
    
    enum CodingKeys: CodingKey {
        case selectedProfileId
        case profiles
    }
    
    public init() {
        selectedProfileId = Settings._selectedProfileId
        profiles = Settings.getProfiles()
    }
    
    public static func getSelectedProfile() -> Profile? {
        var selectedProfile: Profile?
        
        if let index = _profiles.firstIndex(where: { $0.profileId == _selectedProfileId }) {
            selectedProfile = _profiles[index]
        } else {
            selectedProfile = nil
        }
        
        return selectedProfile
    }
    
    public static func setSelectedProfile(profileId: String) {
        _selectedProfileId = profileId
        save()
    }
    
    public static func getProfiles() -> [Profile] {
        return _profiles
    }
    
    public static func saveProfile(profile: Profile) {
        if let index = _profiles.firstIndex(where: { $0.profileId == profile.profileId }) {
            _profiles[index] = profile
        } else {
            _profiles.append(profile)
        }

        save()
    }
    
    private static func save() {
        let settings = Settings()
        
        do {
            let encodedData = try jsonEncoder.encode(settings)
            appGroupDefaults.set(encodedData, forKey: SETTINGS_KEY)
            _ = load()
        } catch {
            NSLog(error.localizedDescription)
        }
    }
    
    public static func load() -> Settings {
        let settings_data = appGroupDefaults.value(forKey: SETTINGS_KEY) as? Data ?? nil
        let value = settings_data != nil ? getValue(data: settings_data!) : Settings()
        
        _selectedProfileId = value.selectedProfileId
        _profiles = value.profiles
        
        return value
    }
    
    private static func getValue(data: Data) -> Settings {
        var value: Settings
        
        do {
            value = try jsonDecoder.decode(Settings.self, from: data)
        } catch {
            value = Settings()
            NSLog(error.localizedDescription)
        }
        
        return value
    }
    
    public static func clean() {
        appGroupDefaults.removeObject(forKey: SETTINGS_KEY)
        _selectedProfileId = ""
        _profiles = []
    }
}
