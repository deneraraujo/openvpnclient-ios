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
                Section(header: Text("configuration-file")) {
                    Button(action: {
                        self.showFilePicker.toggle()
                    }) {
                        Text("pick-file")
                    }
                    .sheet(isPresented: $showFilePicker) {
                        DocumentPicker(callBack: self.viewModel.profile.setConfigFile)
                    }
                    
                    Text(viewModel.profile.serverAddress)
                }.listStyle(PlainListStyle())
                
                Section(header: Text("credentials")) {
                    TextField("username", text: $profile.username)
                    SecureField("password", text: $profile.password)
                }
                
                Section(header: Text("settings")) {
                    Toggle(isOn: $profile.customDNSEnabled) {
                        Text("manage-dns")
                    }
                    
                    if viewModel.profile.customDNSEnabled {
                        List {
                            ForEach(0 ..< viewModel.profile.dnsList.count, id: \.self) { i in
                                TextField("address", text: self.$profile.dnsList[i])
                            }
                        }
                            
                        Button(action: {
                            self.viewModel.addDns()
                        }) {
                            Text("add-address")
                        }
                    }
                }
                
                Section() {
                    Text(connection.message.text)
                    .foregroundColor(viewModel.messageColor())
                    .frame(maxWidth: .infinity)
                    
                    viewModel.mainButton()
                }
                
                Section() {
                    List(viewModel.filteredLog, id: \.self) { log in
                        Text(log.text)
                            .foregroundColor(self.viewModel.logColor(logLevel: log.level))
                    }.id(UUID())
                }
            }
            .navigationBarTitle("app-title")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
