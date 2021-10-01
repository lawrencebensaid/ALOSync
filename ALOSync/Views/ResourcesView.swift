//
//  ContentView.swift
//  ALOSync
//
//  Created by Lawrence Bensaid on 08/09/2021.
//

import SwiftUI
import CoreData

struct ResourcesView: View {
    
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var appContext: AppContext
    
    @AppStorage("showMirror") private var showMirror = false
    
    @FetchRequest<File>(
        sortDescriptors: [NSSortDescriptor(keyPath: \File.name, ascending: true)]
    ) var resources
    
    var body: some View {
        VStack(spacing: 0) {
            if resources.count > 0 {
                if #available(macOS 12, *), appContext.viewMode == .list {
                    ResourcesListView()
                        .environmentObject(appContext)
                } else {
                    ResourcesGridView()
                        .environmentObject(appContext)
                }
            } else {
                VStack {
                    Text("No resources at this time")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.secondary)
                    Button(action: {
                        appContext.fetch(context) {
                            switch $0 {
                            case .failure(let error): appContext.errorMessage = error.localizedDescription; break
                            default: break
                            }
                            appContext.fetchResources(context) {
                                switch $0 {
                                case .failure(let error): appContext.errorMessage = error.localizedDescription; break
                                default: break
                                }
                            }
                        }
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.link)
                    .disabled(appContext.updating)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            SyncStatusBarView {
                HStack(spacing: 16) {
                    if appContext.updating {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text("\(resources.filter({ $0.type == .file }).count) out of \(resources.count) files available for synchronization")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                }
            }
            .help("Resource availability")
        }
        .touchBar { touchBarControls }
        .toolbar {
            if #available(macOS 12, *) {
                Picker("View mode", selection: .init { appContext.viewMode } set: { mode in withAnimation { appContext.viewMode = mode } }) {
                    Image(systemName: "square.grid.2x2").tag(ViewMode.grid)
                    Image(systemName: "list.bullet").tag(ViewMode.list)
                }
                .pickerStyle(.segmented)
            }
        }
        .onAppear {
            appContext.fetch(context) {
                switch $0 {
                case .failure(let error): appContext.errorMessage = error.localizedDescription; break
                default: break
                }
                appContext.fetchResources(context) {
                    switch $0 {
                    case .failure(let error): appContext.errorMessage = error.localizedDescription; break
                    default: break
                    }
                }
            }
        }
    }
    
    var touchBarControls: some View {
        HStack {
            if let resource = resources.filter({ $0.id == appContext.resourceSelection }).first {
                Button(action: {
                    resource.openDirectory()
                }) {
                    Image(systemName: "folder.fill")
                        .padding(.horizontal)
                        .foregroundColor(Color(resource.isSynced() != true ? .disabledControlTextColor : .systemTeal))
                }
                .disabled(resource.isSynced() != true)
                Button(action: {
                    resource.open()
                }) {
                    Image(systemName: "arrow.up.doc.fill")
                        .padding(.horizontal)
                        .foregroundColor(Color(.systemBlue))
                }
                Divider()
                Button(action: {
                    resource.sync { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .failure(let error): appContext.errorMessage = error.localizedDescription
                            default: break
                            }
                        }
                    }
                }) {
                    Image(systemName: "arrow.down.circle.fill")
                        .padding(.horizontal)
                        .foregroundColor(Color(resource.isSynced() == true ? .disabledControlTextColor : .systemGreen))
                }
                .disabled(resource.isSynced() == true)
                Button(action: {
                    resource.offload()
                }) {
                    Image(systemName: "minus.circle.fill")
                        .padding(.horizontal)
                        .foregroundColor(Color(resource.isSynced() == false ? .disabledControlTextColor : .systemRed))
                }
                .disabled(resource.isSynced() == false)
                if showMirror {
                    Divider()
                    Button(action: {
                        appContext.presentMirror.toggle()
                    }) {
                        Image(systemName: "externaldrive.connected.to.line.below")
                            .padding(.horizontal)
                    }
                    .disabled(true) // Causes bug; Temporarily disabled
                }
            }
        }
    }
    
    //    private func update(_ systemName: String) {
    //        DispatchQueue.main.async {
    //            AppDelegate.shared.statusBarItem?.button?.image = NSImage(systemSymbolName: systemName, accessibilityDescription: "Active")
    //        }
    //    }
    
}

struct ResourcesView_Previews: PreviewProvider {
    static var previews: some View {
        ResourcesView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AppContext())
    }
}
