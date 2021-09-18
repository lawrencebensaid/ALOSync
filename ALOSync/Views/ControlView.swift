//
//  ControlView.swift
//  ControlView
//
//  Created by Lawrence Bensaid on 08/09/2021.
//

import SwiftUI

struct ControlView: View {
    
    @EnvironmentObject private var appContext: AppContext
    @AppStorage("token") private var token: String?
    
    var body: some View {
        VStack {
            if token == nil {
                Button("Sign in") { appContext.showLogin = true }
            } else {
                List {
                    Button("Sign out") { token = nil }
                        .buttonStyle(PlainButtonStyle())
                }
                .listStyle(PlainListStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
}

struct ControlView_Previews: PreviewProvider {
    static var previews: some View {
        ControlView()
    }
}
