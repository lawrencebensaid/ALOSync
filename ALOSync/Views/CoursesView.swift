//
//  CoursesView.swift
//  CoursesView
//
//  Created by Lawrence Bensaid on 25/09/2021.
//

import SwiftUI
import CoreData

struct CoursesView: View {
    
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
    
    private var rotation: CGFloat = 0
    
    @FetchRequest<Course>(
        sortDescriptors: [NSSortDescriptor(keyPath: \Course.code, ascending: true)]
    ) var courses
    
    var body: some View {
        VStack(spacing: 0) {
            if courses.count > 0 {
                Table(selection: $appContext.resourceSelection) {
                    TableColumn("Name") {
                        CourseItemView()
                            .environmentObject($0)
                            .environmentObject(appContext)
                            .frame(height: 30)
                            .help($0.summary ?? "")
                    }
                    .width(min: 150, ideal: 500)
                    TableColumn("Code") {
                        Text($0.code)
                            .foregroundColor(.secondary)
                    }
                    .width(min: 100, max: 150)
                    TableColumn("Points") {
                        Text("\($0.points) ECs")
                            .foregroundColor(.secondary)
                    }
                    .width(50)
                    TableColumn("Resources") {
                        Text("\($0.fileCount)")
                            .foregroundColor(.secondary)
                            .help("\($0.fileCount) resources available for sync")
                    }
                    .width(70)
                } rows: {
                    let filtered = courses.filter { query == "" || $0.name.lowercased().contains(query.lowercased()) }
                    ForEach(filtered, id: \.id) { course in
                        TableRow(course)
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
    }
    
}

struct CoursesView_Previews: PreviewProvider {
    static var previews: some View {
        CoursesView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AppContext())
    }
}
