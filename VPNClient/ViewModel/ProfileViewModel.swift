//
//  ProfileViewModel.swift
//  VPNClient
//
//  Created by Dener Araújo on 19/09/20.
//

import SwiftUI

/// Bridge between connection profile and view. Even contains render functions.
public class ProfileViewModel {
    public var connection: Connection
    public var profile: Profile
    
    public init() {
        profile = Profile(profileName: "default", profileId: "default")
        connection = Connection(profile: profile)
    }
    
    /// Set main button action according to connection status
    func mainButtonAction() {
        switch connection.connectionStatus {
        case .invalid, .disconnected:
            connection.startVPN()
            break
        case .connecting, .connected, .reasserting:
            connection.stopVPN()
            break
        case .disconnecting:
            break
        @unknown default:
            connection.startVPN()
            break
        }
    }
    
    /// Define message color according to its level
    func messageColor() -> Color {
        switch connection.message.level {
            case .error: return .red
            case .success: return .green
            case .alert: return .yellow
            case .message: return Color(UIColor.secondaryLabel)
        }
    }

    /// Define log entry color according to its level
    func logColor(logLevel: Log.LogLevel) -> Color {
        switch logLevel {
        case .debug:
            return Color(UIColor.secondaryLabel)
        case .info, .notice:
            return Color(UIColor.label)
        case .warning:
            return .yellow
        case .error, .critical, .alert, .emergency:
            return .red
        }
    }
    
    /// Add new entry to DNS list
    func addDns() {
        profile.dnsList.append("")
    }
    
    /// Define main button style according to connection status
    func mainButton() -> AnyView {
        func button(_ text: String, _ bgColor: Color, textColor: Color = .white, tapable: Bool = true) -> AnyView {
            let button = AnyView(Button(action: {
                Settings.saveProfile(profile: self.profile)
                Settings.setSelectedProfile(profileId: self.profile.profileId)
                
                self.mainButtonAction()
            }) {
                Text(text)
            }.buttonStyle(MainButtonStyle(bgColor: bgColor,
                                         textColor: textColor,
                                         effect: tapable)
            ))
            return button
        }

        switch connection.connectionStatus {
        case .invalid, .disconnected:
            return button(Util.localize("connect"), .green)
        case .connecting:
            return button(Util.localize("cancel"), .yellow)
        case .connected:
            return button(Util.localize("disconnect"), .red)
        case .reasserting:
            return button(Util.localize("cancel"), .yellow)
        case .disconnecting:
            return button(Util.localize("disconnecting"), .yellow, tapable: false)
        @unknown default:
            return button(Util.localize("connect"), .green)
        }
    }
    
    /// Ignore debug level entries if app is not in debug mode
    var filteredLog: [Log] {
        #if DEBUG
        return connection.output
        #else
        return connection.output.filter { $0.level != .debug }
        #endif
    }
}
