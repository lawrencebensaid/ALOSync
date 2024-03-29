//
//  ResourceItemView.swift
//  ResourceItemView
//
//  Created by Lawrence Bensaid on 13/09/2021.
//

import SwiftUI

struct ResourceItemView: View {
    
    private let indentation = 12
    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var resource: File
    @EnvironmentObject private var appContext: AppContext
    
    @AppStorage("syncPath") private var syncPath: String?
    
    @State private var synced = false
    @State private var loading = false
    
    var body: some View {
        HStack(spacing: 4) {
            if resource.type == .course || resource.type == .folder {
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
            Image(systemName: resource.type.systemImage)
                .foregroundColor(.accentColor)
            Text(resource.name)
            Spacer()
            if loading {
                ProgressView()
                    .controlSize(.small)
                    .help("Downloading...")
            } else if synced {
                Image(systemName: "circle.fill")
                    .foregroundColor(.secondary)
                    .help("Downloaded")
            } else if !resource.isSynced(at: syncPath) {
                Button(action: {
                    loading = true
                    resource.sync {
                        if appContext.fsPermissionsHandler($0, { resource.sync() }) { return }
                        switch $0 {
                        case .failure(let error): appContext.errorMessage = error.localizedDescription
                        default: break
                        }
                    }
                }) {
                    Image(systemName: "arrow.down.circle")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .help("Download")
            }
        }
        .padding(.leading, CGFloat(indentation * resource.depth))
        .padding(.vertical, 4)
        .onReceive(timer) { _ in
            if let syncPath = syncPath {
                synced = resource.isSynced(at: syncPath)
                if synced { loading = false }
            }
        }
        .contextMenu {
            Button("Show in Finder") {
                resource.openDirectory()
            }
            .disabled(resource.isSynced() != true)
            Button("Open file") {
                resource.open()
            }
            Divider()
            if let course = resource.course, resource.type == .course, course.canUpdate == true {
                Button("Submit reindexing request") {
                    course.update(viewContext)
                }
            } else {
                Button("Download now") {
                    loading = true
                    resource.sync { result in
                        if appContext.fsPermissionsHandler(result, { resource.sync() }) { return }
                        switch result {
                        case .failure(let error): appContext.errorMessage = error.localizedDescription
                        default: break
                        }
                    }
                }
                .disabled(synced)
                Button("Remove download") {
                    resource.offload { result in
                        switch result {
                        case .failure(let error): appContext.errorMessage = error.localizedDescription
                        default: break
                        }
                    }
                }
                .disabled(!synced)
            }
        }
    }
    
}

struct ResourceItemView_Previews: PreviewProvider {
    static var previews: some View {
        ResourceItemView()
    }
}
