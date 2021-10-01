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
    
    @FetchRequest<Course>(
        sortDescriptors: [NSSortDescriptor(keyPath: \Course.code, ascending: true)]
    ) var courses
    
    var body: some View {
        VStack(spacing: 0) {
            if courses.count > 0 {
                if #available(macOS 12, *), appContext.viewMode == .table {
                    CoursesListView()
                        .environmentObject(appContext)
                } else {
                    CoursesGridView()
                        .environmentObject(appContext)
                }
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
