//
//  Grade.swift
//  Grade
//
//  Created by Lawrence Bensaid on 18/09/2021.
//

import Foundation

class Grade {
    
    static func update() {
        guard let token = UserDefaults.standard.string(forKey: "token") else { return }
        let url = URL(string: "\(ALO.standard.base)/my/grade")!
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
    
}
