//
//  ResourcesGridView.swift
//  ResourcesGridView
//
//  Created by Lawrence Bensaid on 30/09/2021.
//

import SwiftUI

struct ResourcesGridView: View {
    
    private let commonResourceTypes: [File.`Type`] = [.file, .resource]
    
    @EnvironmentObject private var appContext: AppContext
    
    @FetchRequest<File>(
        sortDescriptors: [NSSortDescriptor(keyPath: \File.name, ascending: true)]
    ) var resources
    
    @AppStorage("includeUncommonResources") private var includeUncommonResources = false
    @AppStorage("showFullPathInTooltip") private var showFullPathInTooltip = false
    
    @State private var search = ""
    @State private var query = ""
    
    var body: some View {
        ScrollView {
            let filtered1 = resources.filter { query == "" || $0.name.lowercased().contains(query.lowercased()) }
            let filtered2 = filtered1.filter { includeUncommonResources || commonResourceTypes.contains($0.type) }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                ForEach(filtered2, id: \.id) { resource in
                    ResourceGridItemView()
                        .environmentObject(appContext)
                        .environmentObject(resource)
                }
            }
            .padding(.vertical)
        }
    }
    
}

struct ResourcesGridView_Previews: PreviewProvider {
    static var previews: some View {
        ResourcesGridView()
    }
}
