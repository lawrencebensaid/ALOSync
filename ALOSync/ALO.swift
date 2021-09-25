//
//  ALO.swift
//  ALO
//
//  Created by Lawrence Bensaid on 19/09/2021.
//

import Foundation

class ALO {
    
    public static let standard = ALO()
    
    public static let fallback = ALO()
    
    public enum Setting: String, CaseIterable {
        case authority = "mirrorHost"
        case useTLS = "mirrorTls"
    }
    
    public static func `default`(_ setting: Setting) -> String {
        ALO.standard.default(setting)
    }
    
    public func `default`(_ setting: Setting) -> String {
        switch setting {
        case .authority: return "alo.se0.dev"
        case .useTLS: return "1"
        }
    }
    
    public static func setting(_ setting: Setting) -> String {
        return ALO.standard.setting(setting)
    }
    
    public func setting(_ setting: Setting) -> String {
        return UserDefaults.standard.string(forKey: setting.rawValue) ?? ALO.default(setting)
    }
    
    public func reset() {
        for setting in Setting.allCases {
            UserDefaults.standard.setValue(ALO.default(setting), forKey: setting.rawValue)
        }
    }
    
    public var base: String {
        let scheme = setting(.useTLS) == "1" ? "https" : "http"
        return "\(scheme)://\(setting(.authority))"
    }
    
    public var baseUrl: URL {
        return URL(string: base)!
    }
    
    // Web socket variant
    public var wsBase: String {
        let scheme = setting(.useTLS) == "1" ? "wss" : "ws"
        return "\(scheme)://\(setting(.authority))"
    }
    
    // Web socket variant
    public var wsBaseUrl: URL {
        return URL(string: wsBase)!
    }
    
    public var isDefault: Bool {
        for setting in Setting.allCases {
            if ALO.setting(setting) != ALO.default(setting) {
                return false
            }
        }
        return true
    }
    
//    public var isSignedIn: Bool {
//        if let token = UserDefaults.standard.string(forKey: "token") {
//            return token.count > 0
//        }
//        return false
//    }
    
    private init() { }
    
}
