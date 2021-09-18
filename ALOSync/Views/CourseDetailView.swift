//
//  CourseDetailView.swift
//  CourseDetailView
//
//  Created by Lawrence Bensaid on 13/09/2021.
//

import SwiftUI

struct CourseDetailView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var course: Course
    
    var body: some View {
        VStack {
            Text(course.code)
            Text(course.name)
        }
        .padding()
        .onAppear {
            course.update(viewContext)
        }
    }
    
}

struct CourseDetailView_Previews: PreviewProvider {
    static var previews: some View {
        CourseDetailView()
            .environmentObject(Course.preview(PersistenceController.preview.container.viewContext))
    }
}
