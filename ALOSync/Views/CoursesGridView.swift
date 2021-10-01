//
//  CoursesGridView.swift
//  CoursesGridView
//
//  Created by Lawrence Bensaid on 30/09/2021.
//

import SwiftUI

struct CoursesGridView: View {
    
    @FetchRequest<Course>(
        sortDescriptors: [NSSortDescriptor(keyPath: \Course.code, ascending: true)]
    ) var courses
    
    @State private var query = ""
    
    var body: some View {
        ScrollView {
            let filtered = courses.filter { query == "" || $0.name.lowercased().contains(query.lowercased()) }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))]) {
                ForEach(filtered, id: \.id) { resource in
                    CourseGridItemView()
                        .environmentObject(resource)
                }
            }
            .padding(.vertical)
        }
    }
    
}

struct CoursesGridView_Previews: PreviewProvider {
    static var previews: some View {
        CoursesGridView()
    }
}
