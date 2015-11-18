//
//  AppDelegate.swift
//  BlueSwift
//
//  Created by Yang on 2015/11/17.
//  Copyright © 2015年 Yang. All rights reserved.
//

import UIKit



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        let settings = UIUserNotificationSettings(forTypes: .Alert, categories: nil)
        application.registerUserNotificationSettings(settings);
        
        if let opt = launchOptions
        {
            if let t = opt[UIApplicationLaunchOptionsBluetoothCentralsKey] as? [String]
            {
                NSUserDefaults.standardUserDefaults().setValue(NSDate(), forKey: "relaunchApp")
                NSUserDefaults.standardUserDefaults().setValue(t.first, forKey: "BluetoothCentralsKey")
                NSUserDefaults.standardUserDefaults().synchronize()
                
                if let nav = self.window?.rootViewController as? UINavigationController
                {
                    if let vc = nav.storyboard?.instantiateViewControllerWithIdentifier("CentralVC")
                    {
                        nav.pushViewController(vc, animated: false)
                    }
                }
            }
        }
        
        return true
    }
}

