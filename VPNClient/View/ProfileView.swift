//
//  ProfileView.swift
//  VPNClient
//
//  Created by Dener Araújo on 01/08/20.
//

import SwiftUI

/// A view to create/edit a profile
struct ProfileView: View {
    private var viewModel = ProfileViewModel()
    @ObservedObject var profile: Profile
    @ObservedObject var connection: Connection

    @State var showFilePicker = false
    
    init() {
        self.profile = viewModel.profile
        self.connection = viewModel.connection
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("CONFIGURATION FILE")) {
                    Button(action: {
                        self.showFilePicker.toggle()
                    }) {
                        Text("Pick a \".ovpn\" file")
                    }
                    .sheet(isPresented: $showFilePicker) {
                        DocumentPicker(callBack: self.viewModel.profile.setConfigFile)
                    }
                    
                    Text(viewModel.profile.serverAddress)
                }.listStyle(PlainListStyle())
                
                Section(header: Text("CREDENTIALS")) {
                    TextField("Username", text: $profile.username)
                    SecureField("Password", text: $profile.password)
                }
                
                Section(header: Text("SETTINGS")) {
                    Toggle(isOn: $profile.customDNSEnabled) {
                        Text("Manage DNS servers")
                    }
                    
                    if viewModel.profile.customDNSEnabled {
                        List {
                            ForEach(0 ..< viewModel.profile.dnsList.count, id: \.self) { i in
                                TextField("Address", text: self.$profile.dnsList[i])
                            }
                        }
                            
                        Button(action: {
                            self.viewModel.addDns()
                        }) {
                            Text("Add address")
                        }
                    }
                }
                
                Section() {
                    Text(connection.message.text)
                    .foregroundColor(viewModel.messageColor())
                    .frame(maxWidth: .infinity)
                    
                    viewModel.mainButton()
                }
                
                Section(header: Text("LOG")) {
                    List(connection.output, id: \.self) { log in
                        Text(log.text)
                            .foregroundColor(self.viewModel.logColor(logLevel: log.level))
                    }.id(UUID())
                }
            }
            .navigationBarTitle("OpenVPN Client")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
