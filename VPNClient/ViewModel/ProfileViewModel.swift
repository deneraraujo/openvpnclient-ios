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
        profile = Profile(profileName: "default")
        connection = Connection(profile: profile)
    }
    
    //Set main button action according to connection status
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
    
    //Define message color according to its level
    func messageColor() -> Color {
        switch connection.message.level {
            case .error: return .red
            case .success: return .green
            case .alert: return .yellow
            case .message: return .gray
        }
    }

    //Define log entry color according to its level
    func logColor(logLevel: Log.LogLevel) -> Color {
        switch logLevel {

        case .debug:
            return .gray
        case .info, .notice:
            return .black
        case .warning:
            return .yellow
        case .error, .critical, .alert, .emergency:
            return .red
        }
    }
    
    //Add new entry to DNS list
    func addDns() {
        profile.dnsList.append("")
    }
    
    //Define main button style according to connection status
    func mainButton() -> AnyView {
        func button(_ text: String, _ bgColor: Color, textColor: Color = .white, tapable: Bool = true) -> AnyView {
            let button = AnyView(Button(action: {
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
            return button("Connect", .green)
        case .connecting:
            return button("Cancel", .yellow)
        case .connected:
            return button("Disconnect", .red)
        case .reasserting:
            return button("Cancel", .yellow)
        case .disconnecting:
            return button("Disconnecting...", .yellow, tapable: false)
        @unknown default:
            return button("Connect", .green)
        }
    }
}
