//
//  CourseThumbnailView.swift
//  CourseThumbnailView
//
//  Created by Lawrence Bensaid on 13/09/2021.
//

import SwiftUI

struct CourseThumbnailView: View {
    
    @EnvironmentObject var course: Course
    @State private var thumbnail: Image?
    @State private var loading = false
    
    var body: some View {
        HStack {
            if let thumbnail = thumbnail {
                thumbnail
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 80)
                    .cornerRadius(8)
                    .shadow(radius: 4)
            } else {
                BlurView()
                    .frame(width: 120, height: 80)
                    .cornerRadius(8)
            }
        }
        .onAppear {
            loading = true
            course.thumbnail {
                loading = false
                switch $0 {
                case .success(let image): thumbnail = image
                default: break
                }
            }
        }
    }
}

struct CourseThumbnailView_Previews: PreviewProvider {
    static var previews: some View {
        CourseThumbnailView()
    }
}
