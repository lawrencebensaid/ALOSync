//
//  CourseResource.swift
//  CourseResource
//
//  Created by Lawrence Bensaid on 08/09/2021.
//

import Foundation
import AppKit

public class CourseResource: Decodable, Identifiable, ObservableObject {
    
    public var id: String { fid ?? UUID().uuidString }
    public let fid: String?
    public let name: String
    public let size: Int?
    public let path: String?
    public var courseCode: String? = nil
    public let type: `Type`
    public let subtype: Subtype?
    public let children: [CourseResource]?
    
    public var depth: Int = 1
    public var parent: CourseResource? = nil
    public var course: Course? = nil
    
    private static let systemImages: [`Type`: String] = [
        .unknown: "questionmark",
        .webpage: "globe",
        .folder: "folder",
        .course: "graduationcap.fill",
        .file: "doc",
        .form: "contextualmenu.and.cursorarrow",
        .resource: "link"
    ]
    
    private enum CodingKeys: CodingKey {
        case id
        case name
        case size
        case path
        case type
        case subtype
        case children
    }
    
    public enum `Type`: String, Codable {
        case unknown = "unknown"
        case course = "course"
        case webpage = "webpage"
        case folder = "folder"
        case file = "file"
        case form = "form"
        case resource = "resource"
        @available(*, deprecated, renamed: "webpage")
        case video = "video"
        
        public var systemImage: String { CourseResource.systemImages[self] ?? "questionmark" }
    }
    
    public enum Subtype: String, Codable {
        case pdf = "pdf"
        case docx = "docx"
        case xlsx = "xlsx"
        case pptf = "pptx"
        case mp4 = "mp4"
        
        var label: String {
            switch self {
            case .pdf: return "PDF"
            case .docx: return "Document"
            case .xlsx: return "Excel"
            case .pptf: return "Powerpoint"
            case .mp4: return "mp4"
            }
        }
    }
    
    init(fid: String? = nil, name: String, type: `Type`, subtype: Subtype? = nil, size: Int? = nil, path: String? = nil, course: Course? = nil, depth: Int = 1, children: [CourseResource]? = nil) {
        self.fid = fid
        self.name = name
        self.type = type
        self.subtype = subtype
        self.size = size
        self.path = path
        self.course = course
        self.depth = depth
        self.children = children
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.fid = try container.decodeIfPresent(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        guard let type = `Type`(rawValue: try container.decode(String.self, forKey: .type)) else { throw ParsingError() }
        self.type = type
        let subtype = Subtype(rawValue: try container.decodeIfPresent(String.self, forKey: .subtype) ?? "")
        self.subtype = subtype
        self.size = try container.decodeIfPresent(Int.self, forKey: .size)
        self.path = try container.decodeIfPresent(String.self, forKey: .path)
        self.children = try container.decodeIfPresent([CourseResource].self, forKey: .children)
    }
    
    public func getPath(withSync: Bool = false, includeSelf: Bool = true) -> String {
        var path = ""
        if withSync {
            path = UserDefaults.standard.string(forKey: "syncPath") ?? ""
        }
        if let parent = parent {
            path = "\(path)\(parent.getPath())"
        }
        if includeSelf {
            path = "\(path)/\(name)"
        }
        return path
    }
    
    public func isSynced() -> Bool? {
        guard let path = UserDefaults.standard.string(forKey: "syncPath") else { return nil }
        return isSynced(at: path)
    }
    
    public func isSynced(at path: String?) -> Bool {
        FileManager.default.fileExists(atPath: "\(path ?? "")/\(getPath(includeSelf: true))")
    }
    
    public func open() {
        let destination = "file:\(getPath(withSync: true))"
        if isSynced() == false {
            sync {
                switch $0 {
                case .success: NSWorkspace.shared.open(URL(fileURLWithPath: destination))
                default: break
                }
            }
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: destination))
        }
    }
    
    public func openDirectory() {
        let destination = "file:\(getPath(withSync: true, includeSelf: false))"
        if isSynced() == true {
            NSWorkspace.shared.open(URL(fileURLWithPath: destination))
        }
    }
    
    public func offload(onResult: ((Result<Void, Error>) -> ())? = nil) {
        if FileManager.default.fileExists(atPath: getPath(withSync: true)) {
            do {
                try FileManager.default.removeItem(atPath: getPath(withSync: true))
                onResult?(.success(Void()))
            } catch {
                onResult?(.failure(error))
            }
        }
    }
    
    public func sync(onResult: ((Result<Void, Error>) -> ())? = nil) {
        guard let token = UserDefaults.standard.string(forKey: "token") else { return }
        guard let fid = fid else { return }
        let url = URL(string: "\(UserDefaults.standard.string(forKey: "mirrorHost") ?? "")/file/\(fid)")
        var request = URLRequest(url: url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    onResult?(.failure(error))
                    return
                }
                let status = (response as? HTTPURLResponse)?.statusCode
                if status != 200 {
                    onResult?(.failure(APIError("Failure \(status ?? -1)")))
                    print("\(status ?? -1)")
                    return
                }
                guard let data = data else { return }
                do {
                    if FileManager.default.fileExists(atPath: self.getPath(withSync: true)) {
                        try FileManager.default.removeItem(atPath: self.getPath(withSync: true))
                    }
                    try FileManager.default.createDirectory(atPath: self.getPath(withSync: true, includeSelf: false), withIntermediateDirectories: true)
                    try data.write(to: URL(fileURLWithPath: self.getPath(withSync: true)), options: .atomic)
                    onResult?(.success(Void()))
                } catch {
                    if error.localizedDescription.starts(with: "You don") {
                        onResult?(.failure(FSPermissionsError()))
                    } else {
                        onResult?(.failure(error))
                    }
                }
            }
        }.resume()
    }
    
}
