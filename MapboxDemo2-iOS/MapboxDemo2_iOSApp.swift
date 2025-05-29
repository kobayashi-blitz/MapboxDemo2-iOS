//
//  MapboxDemo2_iOSApp.swift
//  MapboxDemo2-iOS
//
//  Created by Shinya Kobayashi on 2025/05/29.
//

import SwiftUI
import MapboxMaps

@main
struct MapboxDemo2_iOSApp: App {
    init() {
        if let token = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String {
            MapboxOptions.accessToken = token
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
