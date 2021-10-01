//
//  CoursesListView.swift
//  CoursesListView
//
//  Created by Lawrence Bensaid on 30/09/2021.
//

import SwiftUI

@available(macOS 12, *)
struct CoursesListView: View {
    
    @EnvironmentObject private var appContext: AppContext
    
    @State private var search = ""
    @State private var query = ""
    
    @FetchRequest<Course>(
        sortDescriptors: [NSSortDescriptor(keyPath: \Course.code, ascending: true)]
    ) var courses
    
    var body: some View {
        Table(selection: $appContext.resourceSelection) {
            TableColumn("Name") {
                CourseListItemView()
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
        .tableStyle(.inset)
        .searchable(text: $search) {
            List(courses.filter { $0.name.starts(with: search) }) {
                Text($0.name)
            }
        }
        .onSubmit(of: .search) { withAnimation { query = search } }
    }
    
}

@available(macOS 12, *)
struct CoursesListView_Previews: PreviewProvider {
    static var previews: some View {
        CoursesListView()
    }
}
