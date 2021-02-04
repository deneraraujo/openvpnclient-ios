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
    @State var passwordSecured = true
    @State var privKeyPassSecured = true
    
    init() {
        self.profile = viewModel.profile
        self.connection = viewModel.connection
    }

    var body: some View {
        ZStack {
            //if connection.privKeyPassRequired {
            //    AlertControlView(textString: $profile.privateKeyPassword,
            //                     showAlert: $connection.privKeyPassRequired,
            //                     title: "app-title",
            //                     message: "insert-private-key-password",
            //                     placeholder: "private-key-password")
            //}
            NavigationView {
                Form {
                    Section(header: Text("configuration-file")) {
                        HStack {
                            Button(action: {
                                self.showFilePicker.toggle()
                            }) {
                                Text("pick-file")
                            }
                            .sheet(isPresented: $showFilePicker) {
                                DocumentPicker(callBack: self.viewModel.connection.setConfigFile)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .imageScale(.small)
                                .foregroundColor(Color(UIColor.systemBlue))
                        }
                        Text(viewModel.profile.serverAddress)
                    }.listStyle(PlainListStyle())
                    
                    if profile.privKeyPassRequired {
                        Section(header: Text("security")) {
                            HStack {
                                if privKeyPassSecured {
                                    SecureField("private-key-password", text: $profile.privateKeyPassword)
                                } else {
                                    TextField("private-key-password", text: $profile.privateKeyPassword)
                                        .autocapitalization(.none)
                                }
                                Button(action: {
                                    self.privKeyPassSecured.toggle()
                                }) {
                                    Image(systemName: privKeyPassSecured ? "eye.slash" : "eye").imageScale(.medium)
                                        .foregroundColor(Color(UIColor.systemBlue))
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("credentials")) {
                        Toggle(isOn: $profile.anonymousAuth) {
                            Text("anonymous")
                        }
                        
                        if !viewModel.profile.anonymousAuth {
                            TextField("username", text: $profile.username)
                                .autocapitalization(.none)
                            HStack {
                                if passwordSecured {
                                    SecureField("password", text: $profile.password)
                                } else {
                                    TextField("password", text: $profile.password)
                                        .autocapitalization(.none)
                                }
                                Button(action: {
                                    self.passwordSecured.toggle()
                                }) {
                                    Image(systemName: passwordSecured ? "eye.slash" : "eye").imageScale(.medium)
                                        .foregroundColor(Color(UIColor.systemBlue))
                                }
                            }
                        }
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
                            
                            HStack {
                                Button(action: {
                                    self.viewModel.addDns()
                                }) {
                                    Text("add-address")
                                }
                                Spacer()
                                Image(systemName: "plus")
                                    .imageScale(.medium)
                                    .foregroundColor(Color(UIColor.systemBlue))
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
