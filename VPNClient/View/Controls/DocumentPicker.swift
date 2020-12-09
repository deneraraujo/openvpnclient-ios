//
//  DocumentPicker.swift
//  VPNClient
//
//  Created by Dener Araújo on 19/09/20.
//

import SwiftUI

/// File selector control
struct DocumentPicker: UIViewControllerRepresentable {
    var callBack:  (_ data :Data) -> ()
    
    init(callBack: @escaping (_ data: Data) -> Void) {
        self.callBack = callBack
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
                    Log.append("cannot-get-permission-read-file", .error, .mainApp)
                    return
                }
                
                let data = try Data(contentsOf: url)
                parent.callBack(data)
                        
                // Release the security-scoped resource when you are done.
                url.stopAccessingSecurityScopedResource()
                
            } catch let error {
                Log.append(error.localizedDescription, .error, .mainApp)
            }
        }
    }
}
