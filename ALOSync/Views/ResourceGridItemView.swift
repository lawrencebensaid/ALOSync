//
//  ResourceGridItemView.swift
//  ResourceGridItemView
//
//  Created by Lawrence Bensaid on 01/10/2021.
//

import SwiftUI

struct ResourceGridItemView: View {

    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var resource: File
    @EnvironmentObject private var appContext: AppContext
    
    @AppStorage("syncPath") private var syncPath: String?
    
    @State private var synced = false
    @State private var loading = false
    
    var body: some View {
        VStack {
            ZStack {
                Image("GenericDocumentIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50)
                if let subtype = resource.subtype {
                    Text(subtype.rawValue)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gray.opacity(0.7))
                }
            }
            HStack(alignment: .top, spacing: 2) {
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
                Text(resource.name)
                    .help(resource.name)
            }
            .font(.system(size: 12))
            Spacer(minLength: 0)
        }
        .frame(width: 100, height: 90)
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

struct ResourceGridItemView_Previews: PreviewProvider {
    static var previews: some View {
        ResourceGridItemView()
    }
}
