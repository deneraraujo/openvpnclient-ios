//
//  LogView.swift
//  VPNClient
//
//  Created by Dener Araújo on 10/08/20.
//

import SwiftUI

struct LogView: View {
    //@EnvironmentObject var vpn: VPN
    
    var body: some View {
        
        Text("test")
        
        //List(vpn.output, id: \.self) { log in
            //Text(log.text)
                //.rotationEffect(.radians(.pi))
                //.scaleEffect(x: -1, y: 1, anchor: .center)
        //}.id(UUID())
        
        
//        ScrollView(.vertical) {
//            ScrollViewReader { scrollView in
//                LazyVStack {
//                    ForEach(notes, id: \.self) { note in
//                        MessageView(note: note)
//                    }
//                }
//                .onAppear {
//                    scrollView.scrollTo(notes[notes.endIndex - 1])
//                }
//            }
//        }
        
//        List {
//           ForEach(0 ..< vpn.output.count, id: \.self) { i in
//               Text(self.vpn.output[i]).scaleEffect(x: 1, y: -1, anchor: .center)
//           }
//        }.scaleEffect(x: 1, y: -1, anchor: .center)
//
//
//        List {
//            ForEach(0 ..< vpn.output.count, id: \.self) { i in
//                Text(self.vpn.output[i])
//            }
//        }
    }
}

struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        LogView()
    }
}
