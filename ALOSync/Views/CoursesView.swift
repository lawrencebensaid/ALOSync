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
                VStack {
                    Text("No courses at this time")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.secondary)
                    Button(action: {
                        appContext.fetch(context) {
                            switch $0 {
                            case .failure(let error): appContext.errorMessage = error.localizedDescription; break
                            default: break
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
                    Text("\(courses.filter({ $0.canUpdate }).count) out of \(courses.count) courses available for reindexing")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                }
            }
            .help("Course availability")
        }
        .searchable(text: $search) {
            List(courses.filter { $0.name.starts(with: search) }) {
                Text($0.name)
            }
        }
        .onSubmit(of: .search) { withAnimation { query = search } }
        .onAppear {
            appContext.fetch(context) {
                switch $0 {
                case .failure(let error): appContext.errorMessage = error.localizedDescription; break
                default: break
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
