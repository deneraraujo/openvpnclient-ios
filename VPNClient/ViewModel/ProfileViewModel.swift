//
//  ProfileViewModel.swift
//  VPNClient
//
//  Created by Dener Araújo on 19/09/20.
//

import Foundation
import SwiftUI

public class ProfileViewModel: Profile {
    func mainButtonAction() {
        switch connectionStatus {
        case .invalid, .disconnected:
            startVPN()
            break
        case .connecting, .connected, .reasserting:
            stopVPN()
            break
        case .disconnecting:
            break
        @unknown default:
            startVPN()
            break
        }
    }
    
    func messageColor() -> Color {
        switch message.level {
            case .error: return .red
            case .success: return .green
            case .alert: return .yellow
            case .message: return .gray
        }
    }

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
    
    func addRow() {
        dnsList.append("")
    }
    
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

        switch connectionStatus {
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
