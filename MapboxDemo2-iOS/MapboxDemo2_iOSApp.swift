//
//  MapboxDemo2_iOSApp.swift
//  MapboxDemo2-iOS
//
//  Created by Shinya Kobayashi on 2025/05/29.
//

import UIKit
import MapboxMaps

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if let token = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String {
            MapboxOptions.accessToken = token
        }
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = MainViewController()
        window?.makeKeyAndVisible()
        
        return true
    }
}
