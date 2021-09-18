//
//  AppSettingsView.swift
//  AppSettingsView
//
//  Created by Lawrence Bensaid on 18/09/2021.
//

import SwiftUI

struct AppSettingsView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appContext: AppContext
    
    @AppStorage("syncPath") private var syncPath: String?
    @AppStorage("showMirror") private var showMirror = false
    @AppStorage("mirrorHost") private var mirrorHost = "https://alo.se0.dev"
    @AppStorage("showFullPathInTooltip") private var showFullPathInTooltip = false
    @AppStorage("token") private var token: String?
    @AppStorage("developerMode") private var developerMode = false
    
    @State private var presentForget = false
    @State private var presentErase = false
    
    var body: some View {
        TabView {
            Form {
                Section {
                    Toggle("Show full path in Tooltips", isOn: $showFullPathInTooltip)
                        .help("If enabled, displays the full path when hovering over a resource")
                } header: {
                    Text("Preferences")
                        .font(.headline)
                }
                Section {
                    HStack(alignment: .top) {
                        Text(syncPath ?? "Not set")
                            .foregroundColor(syncPath == nil ? Color(.systemRed) : Color(.systemGray))
                            .font(.caption)
                        Button(action: {
                            NSWorkspace.shared.open(URL(fileURLWithPath: "file:\(syncPath ?? "")"))
                        }) {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(Color(.systemGray))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .controlSize(.small)
                        .disabled(syncPath == nil)
                        .help("Reveal in finder")
                        Spacer()
                        Button("Choose...") {
                            let _ = appContext.picker()
                        }
                        .controlSize(.small)
                        .help("Pick a location where your files will be synced to")
                    }
                        .padding(.top, 8)
                        .contextMenu {
                            Button("Clear location") { syncPath = nil }
                        }
                } header: {
                    Text("Sync location")
                        .font(.headline)
                        .padding(.top)
                }
            }
            .padding()
            .tabItem {
                Image(systemName: "slider.horizontal.below.rectangle")
                Text("General")
            }
            Form {
                Section {
                    TextField("Mirror host", text: $mirrorHost)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .help("Server endpoint")
                    Button("Forget auth") {
                        presentForget = true
                    }
                    .help("Clears the authentication token and allows you to re-authenticate.")
                    .alert(isPresented: $presentForget, content: {
                        Alert(title: Text("Forget auth"), primaryButton: .destructive(Text("Forget"), action: { token = nil; presentForget = false }), secondaryButton: .cancel())
                    })
                } header: {
                    Text("Server")
                        .font(.headline)
                }
                Section {
                    Toggle("Show mirror status", isOn: $showMirror)
                        .help("If enabled, allows you to view the status of the mirror server")
                    Toggle("Developer mode", isOn: $developerMode)
                        .help("If enabled, nerdy features will be enabled")
                    Button("Clear cache") {
                        presentErase = true
                    }
                    .help("Clears the entire local database. It will be restored immediately on refresh")
                    .alert(isPresented: $presentErase, content: {
                        Alert(title: Text("Erase local data"), primaryButton: .destructive(Text("Erase"), action: {
                            let request = Course.fetchRequest()
                            let results = try? viewContext.fetch(request)
                            for result in results ?? [] { viewContext.delete(result) }
                            try? viewContext.save()
                            presentErase = false
                        }), secondaryButton: .cancel())
                    })
                } header: {
                    Text("Developer")
                        .font(.headline)
                        .padding(.top)
                }
            }
            .padding()
            .tabItem {
                Image(systemName: "gear")
                Text("Advanced")
            }
        }
        .frame(width: 400, height: 250)
    }
    
}

struct AppSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AppSettingsView()
    }
}
