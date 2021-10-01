//
//  ResourcesListView.swift
//  ResourcesListView
//
//  Created by Lawrence Bensaid on 30/09/2021.
//

import SwiftUI

@available(macOS 12, *)
struct ResourcesListView: View {
    
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
        Table(selection: $appContext.resourceSelection) {
            TableColumn("Name") { resource in
                ResourceItemView()
                    .environmentObject(resource)
                    .environmentObject(appContext)
                    .frame(height: 30)
                    .help(resource.getPath(withSync: showFullPathInTooltip))
                    .onDrag {
                        let fallback = NSItemProvider(object: String(resource.name) as NSString)
                        guard resource.isSynced() == true else { return fallback }
                        let url = URL(fileURLWithPath: resource.getPath(withSync: true))
                        guard let provider = NSItemProvider(contentsOf: url) else { return fallback }
                        return provider
                    }
            }
            .width(min: 150, ideal: 500)
            TableColumn("Course") {
                Text($0.course?.code ?? "")
                    .foregroundColor(.secondary)
                    .help($0.course?.name ?? "")
            }
            .width(min: 100, max: 150)
            TableColumn("Size") {
                if let size = $0.size {
                    Text("\(size.bytesString())")
                        .foregroundColor(.secondary)
                }
            }
            .width(min: 35)
            TableColumn("Kind") {
                Text($0.subtype?.label ?? $0.type.rawValue.capitalized)
                    .foregroundColor(.secondary)
            }
            .width(min: 45)
        } rows: {
            let filtered = resources.filter { query == "" || $0.name.lowercased().contains(query.lowercased()) }
            ForEach(filtered.filter { includeUncommonResources || commonResourceTypes.contains($0.type) }, id: \.id) { resource in
                TableRow(resource)
            }
        }
        .tableStyle(.inset)
        .searchable(text: $search)
        .onSubmit(of: .search) { withAnimation { query = search } }
    }
    
}

@available(macOS 12, *)
struct ResourcesListView_Previews: PreviewProvider {
    static var previews: some View {
        ResourcesListView()
    }
}
