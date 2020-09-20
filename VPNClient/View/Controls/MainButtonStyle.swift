//
//  MainButtonStyle.swift
//  VPNClient
//
//  Created by Dener Araújo on 19/09/20.
//

import SwiftUI

/// Custom style for the main buttons
struct MainButtonStyle: ButtonStyle {
    var bgColor: Color
    var textColor: Color
    var effect: Bool
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding(10)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(bgColor)
                }
            )
            .foregroundColor(textColor)
            .font(.headline)
            .cornerRadius(10)
            .scaleEffect(effect ? (configuration.isPressed ? 0.95: 1) : 1)
            .foregroundColor(.primary)
            //.animation(.spring())
    }
}
