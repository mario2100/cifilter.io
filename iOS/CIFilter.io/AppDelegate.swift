//
//  AppDelegate.swift
//  CIFilter.io
//
//  Created by Noah Gilmore on 11/9/18.
//  Copyright © 2018 Noah Gilmore. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        IQKeyboardManager.shared.enable = true

        let filterNames = CIFilter.filterNames(inCategory: nil)
        let data: [FilterInfo] = filterNames.compactMap { filterName in
            let filter = CIFilter(name: filterName)!
            let filterInfo = try? FilterInfo(filter: filter)
//            if filter.name == "CIDepthBlurEffect" {
////                print(filter.attributes)
////                print(filter.value)
//                print("-------------")
//                filter.setDefaults()
//                for paramName in filterInfo!.parameters.map({ $0.name }) {
//                    print(filter.attributes)
//                    print("\(paramName): \(filter.value(forKey: paramName))")
//                }
//                print("-------------")
//            }
            return filterInfo
        }
//        print(String(data: try! JSONEncoder().encode(data), encoding: .utf8)!)

        window = UIWindow()
        let splitViewController = UISplitViewController()
        let filterListViewController = FilterListViewController(filterInfos: data)
        let navController = UINavigationController(rootViewController: filterListViewController)
        navController.navigationBar.prefersLargeTitles = true
        let filterDetailViewController = FilterDetailViewController()
        filterListViewController.delegate = filterDetailViewController
        filterDetailViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        filterDetailViewController.navigationItem.leftItemsSupplementBackButton = true
        filterDetailViewController.navigationItem.largeTitleDisplayMode = .never
        let detailNavController = UINavigationController(rootViewController: filterDetailViewController)
        splitViewController.viewControllers = [navController, detailNavController]
        splitViewController.delegate = self

        window?.rootViewController = splitViewController
        window?.makeKeyAndVisible()

        // preload built in images
        DispatchQueue.global(qos: .default).async {
            print("\(BuiltInImage.all)")
        }

        splitViewController.toggleMasterView()
//        splitViewController.preferredDisplayMode = .primaryOverlay
        return true
    }

    func appVersion() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }

    func sha() -> String {
        guard let sha = Bundle.main.object(forInfoDictionaryKey: "NGGitSha") as? String else {
            print("WARNING git sha could not be determined")
            #if DEBUG
            fatalError()
            #else
            return "unknown"
            #endif
        }
        return sha
    }

    func commitNumber() -> String {
        guard let number = Bundle.main.object(forInfoDictionaryKey: "NGCommitNumber") as? String else {
            print("WARNING commit number could not be determined")
            fatalError()
        }
        return number
    }
}

extension AppDelegate: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
}

