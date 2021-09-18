//
//  Course+CoreDataClass.swift
//  Course
//
//  Created by Lawrence Bensaid on 08/09/2021.
//
//

import Foundation
import CoreData
import SwiftUI

@objc(Course)
public class Course: NSManagedObject, Decodable, Identifiable {
    
    public var id: String { code }
    public var canUpdate = false
    public var filemap: [CourseResource]?
    public var fileCount: Int { files.count }
    public var files: [CourseResource] {
        var arr: [CourseResource] = []
        for resource in filemap ?? [] {
            arr.append(contentsOf: flatten(resource))
        }
        return arr
    }

    @NSManaged public var code: String
    @NSManaged public var name: String
    @NSManaged public var summary: String?
    @NSManaged public var points: Int16
    
    required convenience public init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[.context] as? NSManagedObjectContext else { fatalError() }
        guard let entity = NSEntityDescription.entity(forEntityName: "Course", in: context) else { fatalError() }
        self.init(entity: entity, insertInto: context)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try container.decode(String.self, forKey: .code)
        self.name = try container.decode(String.self, forKey: .name)
        self.summary = try container.decode(String.self, forKey: .description)
        self.points = try container.decodeIfPresent(Int16.self, forKey: .points) ?? -1
        self.filemap = try container.decodeIfPresent([CourseResource].self, forKey: .filemap)
        self.canUpdate = (try? container.decodeIfPresent(Bool.self, forKey: .canUpdate)) ?? false
        index(filemap)
    }
    
    private func flatten(_ resource: CourseResource) -> [CourseResource] {
        var arr: [CourseResource] = [resource]
        if let children = resource.children {
            for child in children {
                arr.append(contentsOf: flatten(child))
            }
        }
        return arr
    }
    
    private func index(_ resources: [CourseResource]?, parent: CourseResource? = nil, depth: Int = 1) {
        if resources == nil { return }
        for resource in resources ?? [] {
            resource.parent = parent
            resource.course = self
            resource.depth = depth
            if resource.children != nil {
                index(resource.children ?? [], parent: resource, depth: depth + 1)
            }
        }
    }
    
    public func update(_ viewContext: NSManagedObjectContext) {
        guard let token = UserDefaults.standard.string(forKey: "token") else { return }
        guard let host = UserDefaults.standard.string(forKey: "mirrorHost") else { return }
        let url = URL(string: "\(host)/my/course/\(code)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
//            guard let data = data else { return }
//            let decoder = JSONDecoder()
//            decoder.userInfo[.context] = viewContext
//            if let course = try? decoder.decode(Course.self, from: data) {
//                print(course)
//            }
        }.resume()
    }
    
    public func thumbnail(onResult: ((Result<Image, Error>) -> ())? = nil) {
        guard let token = UserDefaults.standard.string(forKey: "token") else { onResult?(.failure(APINotAuthenticatedError())); return }
        var request = URLRequest(url: URL(string: "\(UserDefaults.standard.string(forKey: "mirrorHost") ?? "")/course/\(code)/thumbnail")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                onResult?(.failure(error))
                return
            }
            if let data = data, let image = NSImage(data: data) {
                onResult?(.success(Image(nsImage: image)))
                return
            }
            onResult?(.failure(APIError("Unknown failure")))
        }.resume()
    }
    
    private enum CodingKeys: CodingKey {
        case code
        case name
        case description
        case points
        case filemap
        case canUpdate
    }
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Course> {
        return NSFetchRequest<Course>(entityName: "Course")
    }
    
    public static func preview(_ context: NSManagedObjectContext) -> Course {
        let i = Int.random(in: 10...99)
        let item = Course(context: context)
        item.name = "Course \(i)"
        item.code = "TST.CRS.V\(i)"
        item.summary = "Course \(i)"
        item.points = Int16(i * 2)
        return item
    }

}
