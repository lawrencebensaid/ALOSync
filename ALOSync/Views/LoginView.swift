//
//  LoginView.swift
//  LoginView
//
//  Created by Lawrence Bensaid on 08/09/2021.
//

import SwiftUI

struct LoginView: View {
    
    @EnvironmentObject private var appContext: AppContext
    @AppStorage("token") private var token: String?
    @AppStorage("username") private var username = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var presentHelp = false
    @State private var loading = false
    
    @available(macOS 11.0, *)
    var body: some View {
        VStack {
            Spacer()
            Image("windesheim-logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 64)
                .padding(.bottom)
            if let token = token {
                Text(token)
                Button("Sign out") {
                    self.token = nil
                }
                .controlSize(.large)
            } else {
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .controlSize(.large)
                    .textContentType(.username)
                    .help("Student ID or E-mail")
                    .disabled(loading)
                    .frame(maxWidth: 350)
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .controlSize(.large)
                    .textContentType(.password)
                    .disabled(loading)
                    .frame(maxWidth: 350)
                ZStack {
                    Button(action: { signIn() }) {
                        if loading {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.horizontal)
                        } else {
                            Text("Sign in")
                        }
                    }
                    .disabled(loading)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.top, 16)
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                presentHelp.toggle()
                            }) {
                                Image(systemName: "questionmark")
                            }
                            .clipShape(Circle())
                            .popover(isPresented: $presentHelp) {
                                Text("The user name look like \"s1234567\" or \"s1234567@student.windesheim.nl\"")
                                    .padding()
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .alert(isPresented: .init { errorMessage != nil } set: { _ in errorMessage = nil }, content: {
            Alert(title: Text(errorMessage ?? ""))
        })
    }
    
    private func signIn() {
        guard let url = URL(string: "\(ALO.standard.base)/auth") else { return }
        if username.isEmpty {
            errorMessage = "Enter a username"
            return
        }
        if password.isEmpty {
            errorMessage = "Enter a password"
            return
        }
        loading = true
        let body: [String: String] = ["publicKey": "_", "username": username, "password": password]
        
        let finalBody = try! JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = finalBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            loading = false
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            guard let data = data else { return }
            guard let status = (response as? HTTPURLResponse)?.statusCode else { return }
            if status != 200 {
                print(status)
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                errorMessage = json?["message"] as? String ?? "Something went wrong"
                return
            }
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
            if let token = json?["token"] {
                password = ""
                self.token = token
                DispatchQueue.main.async {
                    appContext.showLogin = false
                }
                return
            }
            errorMessage = "Something went wrong"
        }.resume()
    }
    
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AppContext())
    }
}



