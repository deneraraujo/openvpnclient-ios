//
//  ContentView.swift
//  VPNClient
//
//  Created by Dener Araújo on 01/08/20.
//

import SwiftUI
import MobileCoreServices

struct MainView: View {
    @EnvironmentObject var vpn: VPN

    @State var serverAddress: String = ""
    @State var username: String = ""
    @State var password: String = ""
    @State var customDNSEnabled: Bool = true
    @State var dnsList: [String] = []
    //@State var backgroundColor: Color = Color.clear
    @State var showFilePicker = false
    
    init() {
        //UITableView.appearance().backgroundColor = .clear
        //UITableView.appearance().separatorStyle = .none
        //UITableView.appearance().separatorInset = UIEdgeInsets.zero
        UITableView.appearance().separatorInset = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
    }
    
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
    
    func setConfigFile(configFile: Data) {
        vpn.setConfigFile(configFile: configFile)
        username = vpn.username
        serverAddress = vpn.serverAddress
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

        switch vpn.connectionStatus {
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
    
    func mainButtonAction() {
        func doConnect() {
            vpn.username = self.username
            vpn.password = self.password
            vpn.dnsList = customDNSEnabled ? self.dnsList : []
            vpn.startVPN()
        }
        
        switch vpn.connectionStatus {
        case .invalid, .disconnected:
            doConnect()
            break
        case .connecting, .connected, .reasserting:
            vpn.stopVPN()
            break
        case .disconnecting:
            break
        @unknown default:
            doConnect()
            break
        }
    }
    
    func messageColor() -> Color {
        switch vpn.message.level {
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
                        DocumentPicker(parent: self)
                    }
                    
                    Text(serverAddress)
                }
                
                Section(header: Text("CREDENTIALS")) {
                    TextField("Username", text: $username)
                    SecureField("Password", text: $password)
                }
                
                Section(header: Text("SETTINGS")) {
                    Toggle(isOn: $customDNSEnabled) {
                        Text("Manage DNS servers")
                    }
                    
                    if customDNSEnabled {
                        List {
                            ForEach(0 ..< dnsList.count, id: \.self) { i in
                                TextField("Address", text: self.$dnsList[i])
                            }
                        }
                            
                        Button(action: {
                            self.addRow()
                        }) {
                            Text("Add address")
                        }
                    }
                }
                
                Section() {
                    Text(vpn.message.text)
                    .foregroundColor(messageColor())
                    .frame(maxWidth: .infinity)
                    
                    mainButton()

                    List(vpn.output, id: \.self) { log in
                        Text(log.text)
                            .foregroundColor(self.logColor(logLevel: log.level))
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
    
    private func addRow() {
        self.dnsList.append("")
    }
    
    struct DocumentPicker: UIViewControllerRepresentable {
        var parent: MainView
        
        init(parent: MainView) {
            self.parent = parent
        }
        
        func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: UIViewControllerRepresentableContext<DocumentPicker>) {
        }
        
        func makeCoordinator() -> Coordinator {
            return DocumentPicker.Coordinator(parent: self)
        }
        
        func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPicker>) -> UIDocumentPickerViewController {
            let picker = UIDocumentPickerViewController(documentTypes: ["public.ovpn"], in: .open)
            
            picker.allowsMultipleSelection = false
            picker.delegate = context.coordinator
            
            return picker
        }
        
        class Coordinator: NSObject, UIDocumentPickerDelegate {
            var parent: DocumentPicker
            
            init(parent: DocumentPicker) {
                self.parent = parent
            }
            
            func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
                
                do {
                    // Start accessing a security-scoped resource.
                    guard url.startAccessingSecurityScopedResource() else {
                        Log.append("Cannot get permission to raad the file.", .error, .mainApp)
                        return
                    }
                    
                    let data = try Data(contentsOf: url)
                    parent.parent.setConfigFile(configFile: data)
                            
                    // Release the security-scoped resource when you are done.
                    url.stopAccessingSecurityScopedResource()
                    
                } catch let error {
                    Log.append(error.localizedDescription, .error, .mainApp)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
