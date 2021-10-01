//
//  CourseGridItemView.swift
//  CourseGridItemView
//
//  Created by Lawrence Bensaid on 30/09/2021.
//

import SwiftUI

struct CourseGridItemView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var course: Course
    @EnvironmentObject private var appContext: AppContext
    
    @AppStorage("syncPath") private var syncPath: String?
    
    @State private var synced = false
    @State private var loading = false
    @State private var presentIndexingInfo = false
    
    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                if #available(macOS 12.0, *) {
                    AsyncImage(url: URL(string: "\(ALO.standard.base)/course/\(course.code)/thumbnail")!) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 80)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                    } placeholder: {
                        BlurView()
                            .frame(width: 120, height: 80)
                            .cornerRadius(8)
                    }
                } else {
                    CourseThumbnailView()
                        .environmentObject(course)
                        .frame(width: 30)
                }
                Button(action: {
                    presentIndexingInfo.toggle()
                }) {
                    if loading {
                        ProgressView()
                            .controlSize(.small)
                    } else if course.canUpdate {
                        Image(systemName: "info.circle.fill")
                            .shadow(radius: 2)
                    }
                }
                .buttonStyle(.plain)
                .disabled(loading)
                .padding(4)
                .popover(isPresented: $presentIndexingInfo) {
                    Text("Reindexing available for \(course.code)")
                        .padding()
                }
            }
            Text(course.name)
                .help(course.name)
            Spacer(minLength: 0)
        }
        .frame(width: 140, height: 120)
        .contextMenu {
            if course.canUpdate == true {
                Button("Submit reindexing request") {
                    course.update(viewContext)
                }
            }
        }
    }
    
}

struct CourseGridItemView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        CourseGridItemView()
            .environment(\.managedObjectContext, context)
            .environmentObject(Course.preview(context))
    }
}
