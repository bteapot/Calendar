//
//  AppDelegate.swift
//  Example
//
//  Created by Денис Либит on 27.04.2022.
//

import UIKit
import Calendar


@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = {
            let vc = ViewController()
            let nc = UINavigationController(rootViewController: vc)
            nc.setup()
            
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.tintColor = CalendarVC.Style.default.colors.tint
            window.rootViewController = nc
            window.makeKeyAndVisible()
            
            return window
        }()
        
        return true
    }
}

private extension UINavigationController {
    func setup() {
        self.navigationBar.standardAppearance = {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            //appearance.backgroundColor = .cyan.withAlphaComponent(0.15)
            appearance.titleTextAttributes = [
                .foregroundColor: CalendarVC.Style.default.colors.tint,
            ]
            return appearance
        }()
        self.navigationBar.scrollEdgeAppearance = self.navigationBar.standardAppearance
        self.navigationBar.compactAppearance = self.navigationBar.standardAppearance
        self.navigationBar.tintColor = CalendarVC.Style.default.colors.tint
    }
}
