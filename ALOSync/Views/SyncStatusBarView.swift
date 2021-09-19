//
//  SyncStatusBarView.swift
//  SyncStatusBarView
//
//  Created by Lawrence Bensaid on 19/09/2021.
//

import SwiftUI

struct SyncStatusBarView: View {
    
    @FetchRequest(entity: Course.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Course.code, ascending: true)]) var courses: FetchedResults<Course>
    
    @Binding private var loading: Bool
    
    init(loading: Binding<Bool>) {
        _loading = loading
    }
    
    var body: some View {
        let resources = courses.flatMap { $0.files }
        VStack(spacing: 0) {
            Rectangle()
                .foregroundColor(Color("Divider2"))
                .frame(maxWidth: .infinity, minHeight: 0.5, maxHeight: 0.5)
            Spacer(minLength: 0)
            HStack(spacing: 16) {
                if loading {
                    ProgressView()
                        .controlSize(.small)
                }
                Text("\(resources.filter({ $0.type == .file }).count) out of \(resources.count) files available for synchronization")
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))
            }
            .frame(maxWidth: .infinity)
            .offset(y: -1)
            .help("Show resource availability")
            Spacer(minLength: 0)
        }
        .background(BlurView())
        .frame(height: 28)
    }
    
}

struct SyncStatusBarView_Previews: PreviewProvider {
    static var previews: some View {
        SyncStatusBarView(loading: .constant(true))
    }
}
