//
//  ProfileView.swift
//  VPNClient
//
//  Created by Dener Araújo on 01/08/20.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel = ProfileViewModel()

    @State var showFilePicker = false
    
    init() {
        UITableView.appearance().separatorInset = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
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
                        DocumentPicker(callBack: self.viewModel.setConfigFile)
                    }
                    
                    Text(viewModel.serverAddress)
                }
                
                Section(header: Text("CREDENTIALS")) {
                    TextField("Username", text: $viewModel.username)
                    SecureField("Password", text: $viewModel.password)
                }
                
                Section(header: Text("SETTINGS")) {
                    Toggle(isOn: $viewModel.customDNSEnabled) {
                        Text("Manage DNS servers")
                    }
                    
                    if viewModel.customDNSEnabled {
                        List {
                            ForEach(0 ..< viewModel.dnsList.count, id: \.self) { i in
                                TextField("Address", text: self.$viewModel.dnsList[i])
                            }
                        }
                            
                        Button(action: {
                            self.viewModel.addRow()
                        }) {
                            Text("Add address")
                        }
                    }
                }
                
                Section() {
                    Text(viewModel.message.text)
                    .foregroundColor(viewModel.messageColor())
                    .frame(maxWidth: .infinity)
                    
                    viewModel.mainButton()

                    List(viewModel.output, id: \.self) { log in
                        Text(log.text)
                            .foregroundColor(self.viewModel.logColor(logLevel: log.level))
                    }.id(UUID())
                    
                    //Text(vpn.output.joined(separator: "\n\n"))
                    //.lineLimit(nil)

                    //NavigationLink(destination: LogView()) {
                    //    Text("Show log")
                    //}
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
