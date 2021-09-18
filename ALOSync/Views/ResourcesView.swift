//
//  ContentView.swift
//  ALOSync
//
//  Created by Lawrence Bensaid on 08/09/2021.
//

import SwiftUI
import CoreData

struct ResourcesView: View {
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var appContext: AppContext
    
    @AppStorage("token") private var token: String?
    @AppStorage("syncPath") private var syncPath: String?
    @AppStorage("showMirror") private var showMirror = false
    @AppStorage("showFullPathInTooltip") private var showFullPathInTooltip = false
    
    @State private var isUpdated = false
    @State private var presentStatus = false
    @State private var loading = false
    @State private var filterCourses = true
    
    private var rotation: CGFloat = 0
    
    @FetchRequest(entity: Course.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Course.code, ascending: true)]) var courses: FetchedResults<Course>
    
    var body: some View {
        VStack {
            if courses.count > 0 {
                if #available(macOS 12.0, *) {
                    Table(selection: $appContext.resourceSelection) {
                        TableColumn("Name") { resource in
                            ResourceItemView()
                                .environmentObject(resource)
                                .environmentObject(appContext)
                                .frame(height: 30)
                                .help(resource.getPath(withSync: showFullPathInTooltip))
                        }
                        .width(min: 150, ideal: 500)
                        TableColumn("Size") {
                            if let size = $0.size {
                                Text("\(size.bytesString())")
                                    .foregroundColor(Color(.secondaryLabelColor))
                            }
                        }
                        .width(min: 35)
                        TableColumn("Kind") {
                            Text($0.subtype?.label ?? $0.type.rawValue.capitalized)
                                .foregroundColor(Color(.secondaryLabelColor))
                        }
                        .width(min: 45)
                    } rows: {
                        ForEach(courses.filter { filterCourses ? $0.fileCount > 0 : true }, id: \.id) { course in
                            TableRow(CourseResource(name: course.name, type: .course, course: course, depth: 0))
                            ForEach(course.files) { resource in
                                TableRow(resource)
                            }
                        }
                    }
                    .onReceive(appContext.$resourceSelection) { selection in
                        appContext.resource = courses.flatMap({ $0.files }).filter({ $0.id == selection }).first
                    }
                } else {
                    List(courses.filter { $0.fileCount > 0 }) { course in
                        ResourceItemView()
                            .environmentObject(CourseResource(name: course.name, type: .course, depth: 0))
                            .environmentObject(appContext)
                            .frame(height: 30)
                        VStack(alignment: .leading) {
                            if let resources = course.files {
                                ForEach(resources) { resource in
                                    ResourceItemView()
                                        .environmentObject(resource)
                                        .environmentObject(appContext)
                                        .frame(height: 30)
                                }
                            }
                        }
                    }
                }
            } else {
                Button("Refresh") {
                    loading = true
                    appContext.fetch(context) {
                        loading = false
                        switch $0 {
                        case .failure(let error): appContext.errorMessage = error.localizedDescription; break
                        default: break
                        }
                    }
                }
                .controlSize(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .touchBar { touchBarControls }
        .toolbar {
            if loading {
                ProgressView()
                    .controlSize(.small)
            }
            Button(action: {
                presentStatus.toggle()
            }) {
                Image(systemName: "info.circle")
            }
            .help("Show resource availability")
            .popover(isPresented: $presentStatus) {
                let resources = courses.flatMap { $0.files }
                Text("\(resources.filter({ $0.type == .file }).count) out of \(resources.count) files available for synchronization")
                    .padding()
            }
            Toggle(isOn: .init { filterCourses } set: { x in withAnimation { filterCourses = x } }) {
                Image(systemName: "graduationcap")
            }
            .help("Only show courses containing files/resources")
        }
        .onAppear {
            loading = true
            appContext.fetch(context) {
                loading = false
                switch $0 {
                case .failure(let error): appContext.errorMessage = error.localizedDescription; break
                default: break
                }
            }
        }
        .onReceive(timer) { _ in
            guard let image = AppDelegate.shared.statusBarItem?.button?.image else { return }
            AppDelegate.shared.statusBarItem?.button?.image = image.rotated(by: 90)
        }
    }
    
    var touchBarControls: some View {
        HStack {
            let resources = courses.flatMap { $0.files }
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
                        Image(systemName: "slider.horizontal.below.rectangle")
                            .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    private func update(_ systemName: String) {
        DispatchQueue.main.async {
            AppDelegate.shared.statusBarItem?.button?.image = NSImage(systemSymbolName: systemName, accessibilityDescription: "Active")
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ResourcesView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AppContext())
    }
}
