//
//  File.swift
//  File
//
//  Created by Lawrence Bensaid on 22/09/2021.
//
//

import AppKit
import CoreData

@objc(File)
public class File: NSManagedObject, ResourceModel, Decodable {
    
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var size: Int64
    @NSManaged private var type_: String
    @NSManaged private var subtype_: String?
    @NSManaged public var directory: String?
    
    public var type: `Type` { get { `Type`(rawValue: type_) ?? .unknown } set { type_ = newValue.rawValue } }
    public var subtype: Subtype? { get { subtype_ != nil ? Subtype(rawValue: subtype_!) : nil } set { subtype_ = newValue?.rawValue } }
    
    public var depth: Int = 1
    public var parent: Resource? = nil
    @NSManaged public var course: Course?
    
    required convenience public init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[.context] as? NSManagedObjectContext else { fatalError() }
        guard let entity = NSEntityDescription.entity(forEntityName: "File", in: context) else { fatalError() }
        self.init(entity: entity, insertInto: context)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.size = (try? container.decodeIfPresent(Int64.self, forKey: .size)) ?? -1
        self.type_ = try container.decode(String.self, forKey: .type)
        self.subtype_ = try container.decodeIfPresent(String.self, forKey: .subtype)
        self.directory = try container.decodeIfPresent(String.self, forKey: .directory)
        if let course = try? container.decodeIfPresent([String: String].self, forKey: .course), let code = course["code"] {
            let results = (try? context.fetch(Course.fetchRequest())) ?? []
            self.course = results.filter({ $0.code == code }).first
        } else {
            self.course = nil
        }
    }
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<File> {
        return NSFetchRequest<File>(entityName: "File")
    }
    
    private enum CodingKeys: CodingKey {
        case id
        case name
        case size
        case type
        case subtype
        case directory
        case course
    }
    
    public enum `Type`: String, Codable {
        case unknown = "unknown"
        case course = "course"
        case webpage = "webpage"
        case folder = "folder"
        case file = "file"
        case form = "form"
        case resource = "resource"
        case video = "video"
        
        public var systemImage: String { File.systemImages[self] ?? "questionmark" }
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
    
    private static let systemImages: [`Type`: String] = [
        .unknown: "questionmark",
        .folder: "folder",
        .course: "graduationcap.fill",
        .file: "doc",
        .form: "contextualmenu.and.cursorarrow",
        .resource: "link"
    ]
    
    public func getPath(withSync: Bool = false, includeSelf: Bool = true) -> String {
        var path = ""
        if withSync {
            path = UserDefaults.standard.string(forKey: "syncPath") ?? ""
        }
        if let directory = directory {
            path = "\(path)/\(directory)"
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
        let url = URL(string: "\(ALO.standard.base)/file/\(id)")
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

protocol ResourceModel: Identifiable {
    
    var id: String { get set }
    var name: String { get set }
    var size: Int64 { get set }
    
}
