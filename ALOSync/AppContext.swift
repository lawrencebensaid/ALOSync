//
//  AppContext.swift
//  AppContext
//
//  Created by Lawrence Bensaid on 13/09/2021.
//

import Foundation
import CoreData
import SwiftUI

class AppContext: ObservableObject {
    
    @Published public var updating = false
    @Published public var showLogin = false
    @Published public var errorMessage: String?
    @Published public var resourceSelection: String?
    
    // Developer mode
    @Published public var presentMirror = false // Causes memory leak, maybe a SwiftUI bug?
    
    init() { }
    
    public func offloadAll(_ viewContext: NSManagedObjectContext) {
        let request = File.fetchRequest()
        let results = (try? viewContext.fetch(request)) ?? []
        for resource in results { resource.offload() }
    }
    
    public func fetch(_ context: NSManagedObjectContext, _ complete: ((Result<[Course], APIError>) -> ())? = nil) {
        guard let token = UserDefaults.standard.string(forKey: "token") else { return }
        var request = URLRequest(url: URL(string: "\(ALO.standard.base)/my/course")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        updating = true
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.updating = false
                if let error = error {
                    complete?(.failure(APIError("Something went wrong")))
                    print(error.localizedDescription)
                    return
                }
                guard let data = data else { return }
                guard let status = (response as? HTTPURLResponse)?.statusCode else { return }
                if status != 200 {
                    print(status)
                    let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    complete?(.failure(APIError(json?["message"] as? String ?? "Something went wrong")))
                    return
                }
                let decoder = JSONDecoder()
                decoder.userInfo[.context] = context
//                withAnimation {
                    let results = (try? context.fetch(Course.fetchRequest())) ?? []
                    for result in results { context.delete(result) }
                    if let courses = try? decoder.decode([Course].self, from: data) {
                        try? context.save()
                        complete?(.success(courses))
                        return
                    }
                    complete?(.failure(APIError("Something went wrong")))
//                }
            }
        }.resume()
    }
    
    public func fetchResources(_ context: NSManagedObjectContext, _ complete: ((Result<[File], APIError>) -> ())? = nil) {
        guard let token = UserDefaults.standard.string(forKey: "token") else { return }
        var request = URLRequest(url: URL(string: "\(ALO.standard.base)/my/resource")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        updating = true
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.updating = false
                if let error = error {
                    complete?(.failure(APIError("Something went wrong")))
                    print(error.localizedDescription)
                    return
                }
                guard let data = data else { return }
                guard let status = (response as? HTTPURLResponse)?.statusCode else { return }
                if status != 200 {
                    print(status)
                    let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    complete?(.failure(APIError(json?["message"] as? String ?? "Something went wrong")))
                    return
                }
                let decoder = JSONDecoder()
                decoder.userInfo[.context] = context
                let results = (try? context.fetch(File.fetchRequest())) ?? []
                for result in results { context.delete(result) }
                if let courses = try? decoder.decode([File].self, from: data) {
                    try? context.save()
                    complete?(.success(courses))
                    return
                }
                complete?(.failure(APIError("Something went wrong")))
            }
        }.resume()
    }
    
    public func picker() -> Bool {
        let dialog = NSOpenPanel();
        dialog.title = "Choose sync location";
        dialog.message = "This will be the location where the downloaded files will be stored"
        dialog.canChooseFiles = false
        dialog.canCreateDirectories = true
        dialog.showsResizeIndicator = true;
        dialog.showsHiddenFiles = true;
        dialog.allowsMultipleSelection = false;
        dialog.canChooseDirectories = true;
        
        if dialog.runModal() == .OK {
            if let path = dialog.url?.path {
                UserDefaults.standard.set(path, forKey: "syncPath")
                return true
            }
        }
        return false
    }
    
    func fsPermissionsHandler(_ result: Result<Void, Error>, _ continual: (() -> ())? = nil) -> Bool {
        switch result {
        case .failure(let error):
            if let _ = error as? FSPermissionsError, picker() {
                continual?()
                return true
            }
        default: break
        }
        return false
    }
    
}
