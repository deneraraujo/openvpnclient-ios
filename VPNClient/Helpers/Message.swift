//
//  Message.swift
//  VPNClient
//
//  Created by Dener Araújo on 18/09/20.
//

import Foundation

/// Structure for a output message
public struct Message {
    public enum MessageLevel {
        case error
        case success
        case alert
        case message
    }
    
    var text: String
    var level: MessageLevel
    
    init(_ text: String, _ level : MessageLevel = MessageLevel.message) {
        self.text = text
        self.level = level
    }
}
