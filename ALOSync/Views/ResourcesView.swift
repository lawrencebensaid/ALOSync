//
//  ContentView.swift
//  ALOSync
//
//  Created by Lawrence Bensaid on 08/09/2021.
//

import SwiftUI
import CoreData

struct ResourcesView: View {
    
//    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let commonResourceTypes: [File.`Type`] = [.file, .resource]
    
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var appContext: AppContext
    
    @AppStorage("token") private var token: String?
    @AppStorage("syncPath") private var syncPath: String?
    @AppStorage("showMirror") private var showMirror = false
    @AppStorage("includeUncommonResources") private var includeUncommonResources = false
    @AppStorage("showFullPathInTooltip") private var showFullPathInTooltip = false
    
    @State private var isUpdated = false
    @State private var presentStatus = false
    @State private var filterCourses = true
    @State private var search = ""
    @State private var query = ""
    
//    private var rotation: CGFloat = 0
    
    @FetchRequest<File>(
        sortDescriptors: [NSSortDescriptor(keyPath: \File.name, ascending: true)]
    ) var resources
    
    var body: some View {
        VStack(spacing: 0) {
            if resources.count > 0 {
                Table(selection: $appContext.resourceSelection) {
                    TableColumn("Name") { resource in
                        ResourceItemView()
                            .environmentObject(resource)
                            .environmentObject(appContext)
                            .frame(height: 30)
                            .help(resource.getPath(withSync: showFullPathInTooltip))
                            .onDrag {
                                let fallback = NSItemProvider(object: String(resource.name) as NSString)
                                guard resource.isSynced() == true else { return fallback }
                                let url = URL(fileURLWithPath: resource.getPath(withSync: true))
                                guard let provider = NSItemProvider(contentsOf: url) else { return fallback }
                                return provider
                            }
                    }
                    .width(min: 150, ideal: 500)
                    TableColumn("Course") {
                        Text($0.course?.code ?? "None")
                            .foregroundColor(.secondary)
                    }
                    TableColumn("Size") {
                        if let size = $0.size {
                            Text("\(size.bytesString())")
                                .foregroundColor(.secondary)
                        }
                    }
                    .width(min: 35)
                    TableColumn("Kind") {
                        Text($0.subtype?.label ?? $0.type.rawValue.capitalized)
                            .foregroundColor(.secondary)
                    }
                    .width(min: 45)
                } rows: {
                    let filtered = resources.filter { query == "" || $0.name.lowercased().contains(query.lowercased()) }
                    ForEach(filtered.filter { includeUncommonResources || commonResourceTypes.contains($0.type) }, id: \.id) { resource in
                        TableRow(resource)
                    }
                }
                .tableStyle(InsetTableStyle())
            } else {
                Button("Refresh") {
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
                .controlSize(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            SyncStatusBarView(loading: $appContext.updating)
        }
        .searchable(text: $search)
        .onSubmit(of: .search) { withAnimation { query = search } }
        .touchBar { touchBarControls }
        .toolbar {
            Toggle(isOn: .init { filterCourses } set: { x in withAnimation { filterCourses = x } }) {
                Image(systemName: "graduationcap")
            }
            .help("Only show courses containing files/resources")
            .keyboardShortcut("f", modifiers: [.command, .shift])
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
//        .onReceive(timer) { _ in
//            guard let image = AppDelegate.shared.statusBarItem?.button?.image else { return }
//            AppDelegate.shared.statusBarItem?.button?.image = image.rotated(by: 90)
//        }
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
