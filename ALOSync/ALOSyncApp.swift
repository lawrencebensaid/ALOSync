//
//  ALOSyncApp.swift
//  ALOSync
//
//  Created by Lawrence Bensaid on 08/09/2021.
//

import SwiftUI

@main
struct ALOSyncApp: App {
    
    private let viewContext = PersistenceController.shared.container.viewContext
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @ObservedObject private var appContext = AppContext()
    
    @AppStorage("token") private var token: String?
    @AppStorage("showMirror") private var showMirror = false
    @AppStorage("developerMode") private var developerMode = false
    
    @State private var artifact = 1
    @State private var synced: Bool?
    @State private var presentMirror = false
    
    init() {
        appDelegate.appContext = appContext
        appDelegate.viewContext = viewContext
        AppDelegate.shared = self.appDelegate
    }
    
    var body: some Scene {
        WindowGroup {
            if ALO.standard.isSignedIn {
                HStack {
                    ResourcesView()
                        .environment(\.managedObjectContext, viewContext)
                        .environmentObject(appContext)
                        .navigationTitle("Resources")
                }
                .frame(minWidth: 550, minHeight: 250)
                .toolbar {
                    ToolbarItem(placement: .status) {
                        if showMirror {
                            Button(action: {
                                // appContext.presentMirror.toggle() // Temprarily disabled
                                presentMirror.toggle()
                            }) {
                                Image(systemName: "externaldrive.connected.to.line.below")
                            }
                            .help("Show mirror server status")
                            .keyboardShortcut("s", modifiers: [.control, .option])
                            .popover(isPresented: $presentMirror) {
                                StatusView()
                                    .environmentObject(appContext)
                            }
                        }
                    }
                }
                .alert(isPresented: .init { appContext.errorMessage != nil } set: { _ in appContext.errorMessage = nil }) {
                    Alert(title: Text(appContext.errorMessage ?? ""))
                }
            } else {
                LoginView()
                    .environmentObject(appContext)
                    .frame(width: 450, height: 250)
                    .presentedWindowStyle(HiddenTitleBarWindowStyle())
                    .navigationTitle("Sign in")
            }
        }
        .commands {
            let courses: [Course]? = (try? viewContext.fetch(Course.fetchRequest())).flatMap({ $0 })
            let resource = courses?.flatMap({ $0.files }).filter({ $0.id == appContext.resourceSelection }).first
            CommandGroup(after: .newItem) {
                Button("Show in Finder") {
                    resource?.openDirectory()
                }
                .disabled(resource == nil || resource?.isSynced() != true)
                .keyboardShortcut("o", modifiers: [.command, .shift])
                Button("Open file") {
                    resource?.open()
                }
                .disabled(resource == nil)
                .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(before: .importExport) {
                Button("Sync location...") {
                    let _ = appContext.picker()
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
            }
            CommandMenu("View") {
                Button("Reload content") {
                    appContext.fetch(viewContext)
                }
                .keyboardShortcut("r", modifiers: .command)
                if showMirror {
                    Divider()
                    Button("Show server status") {
                        appContext.presentMirror.toggle()
                    }
                    .keyboardShortcut("s", modifiers: [.control, .option])
                    .disabled(true) // Causes bug; temporarily disabled
                }
            }
            CommandMenu("Resource") {
                Button("Download now") {
                    resource?.sync()
                }
                .disabled(resource?.isSynced() != false)
                Button("Remove download") {
                    resource?.offload()
                }
                .disabled(resource?.isSynced() != true)
                Divider()
                Button("Offload all") {
                    appContext.offloadAll(viewContext)
                }
                .keyboardShortcut(.delete, modifiers: .command)
                if developerMode {
                    Divider()
                    Button("Fetch grades (BETA)") {
                        Grade.update()
                    }
                }
            }
        }
        Settings {
            AppSettingsView()
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(appContext)
        }
    }
    
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var viewContext: NSManagedObjectContext?
    var appContext: AppContext?
    var popover = NSPopover()
    var statusBarItem: NSStatusItem?
    static var shared : AppDelegate!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        let contentView = ControlView()
            .environment(\.managedObjectContext, viewContext!)
            .environmentObject(appContext!)
        
        popover.behavior = .transient
        popover.animates = false
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = NSHostingView(rootView: contentView)
        popover.contentViewController?.view.window?.makeKey()
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem?.button?.image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: "Active")
        statusBarItem?.button?.action = #selector(AppDelegate.togglePopover(_:))
    }
    
    @objc func showPopover(_ sender: AnyObject?) {
        if let button = statusBarItem?.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    @objc func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
    
}

public struct ParsingError: Error {}

public struct FSPermissionsError: Error {}

public struct APINotAuthenticatedError: Error {}

public struct APIError: Error {
    public var localizedDescription: String
    
    init(_ message: String) {
        localizedDescription = message
    }
}
