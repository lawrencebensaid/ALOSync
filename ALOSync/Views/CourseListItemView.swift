//
//  CourseListItemView.swift
//  CourseListItemView
//
//  Created by Lawrence Bensaid on 25/09/2021.
//

import SwiftUI

struct CourseListItemView: View {
    
    private let indentation = 12
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var course: Course
    @EnvironmentObject private var appContext: AppContext
    
    @AppStorage("syncPath") private var syncPath: String?
    
    @State private var synced = false
    @State private var loading = false
    
    var body: some View {
        HStack(spacing: 4) {
            if #available(macOS 12.0, *) {
                AsyncImage(url: URL(string: "\(ALO.standard.base)/course/\(course.code)/thumbnail")!) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 30, height: 20)
                        .cornerRadius(4)
                        .shadow(radius: 2)
                } placeholder: {
                    BlurView()
                        .frame(width: 30, height: 20)
                        .cornerRadius(4)
                }
            } else {
                CourseThumbnailView()
                    .environmentObject(course)
                    .frame(width: 30)
            }
            if false {
                Button(action: {
                    
                }) {
                    Image(systemName: "chevron.down")
                        .foregroundColor(Color(.labelColor))
                        .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.plain)
                .disabled(true)
                .frame(width: 12)
            } else {
                Spacer()
                    .frame(width: 12)
            }
            Text(course.name)
            Spacer()
            if loading {
                ProgressView()
                    .controlSize(.small)
            } else if course.canUpdate {
                Text("Reindexing available")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            if course.canUpdate == true {
                Button("Submit reindexing request") {
                    course.update(viewContext)
                }
            }
        }
    }
    
}

struct CourseItemView_Previews: PreviewProvider {
    static var previews: some View {
        CourseListItemView()
    }
}
