//
//  AppDelegate.swift
//  PushApp
//
//  Created by Sierra on 3/12/17.
//  Copyright © 2017 mobile. All rights reserved.
//

import UIKit
import UserNotifications
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        application.applicationIconBadgeNumber = 0
        self.registerForPushNotifications(application: application)
        
        self.registerLocalNotification()
        
        if let notification = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? [String: Any] {
          print(notification.debugDescription)
        }
        
        FIRApp.configure()
        
        // [START add_token_refresh_observer]
        // Add observer for InstanceID token refresh callback.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.tokenRefreshNotification),
                                               name: .firInstanceIDTokenRefresh,
                                               object: nil)
        
        // [END add_token_refresh_observer]
        
        return true
    }
    
    // [START refresh_token]
    func tokenRefreshNotification(_ notification: Notification) {
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            print("InstanceID token: \(refreshedToken)")
        }
        
        // Connect to FCM since connection may have failed when attempted before having a token.
        connectToFcm()
    }
    
    // [START connect_to_fcm]
    func connectToFcm() {
        // Won't connect since there is no token
        guard FIRInstanceID.instanceID().token() != nil else {
            return;
        }
        
        // Disconnect previous FCM connection if it exists.
        FIRMessaging.messaging().disconnect()
        
        FIRMessaging.messaging().connect { (error) in
            if error != nil {
                print("Unable to connect with FCM. \(error)")
            } else {
                print("Connected to FCM.")
            }
        }
    }
    // [END connect_to_fcm]
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        FIRMessaging.messaging().disconnect()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        connectToFcm()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Handle push from foreground")
        // custom code to handle push while app is in the foreground
        print("\(notification.request.content.userInfo)")
        
        if let messageID = notification.request.content.userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Play a sound.
        completionHandler(UNNotificationPresentationOptions.sound)
        
        self.processNotification()
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Handle push from background or closed")
        // if you set a member variable in didReceiveRemoteNotification, you  will know if this is from closed or background
        print("\(response.notification.request.content.userInfo)")
        
        if let messageID = response.notification.request.content.userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        self.processNotification()
        
        if response.actionIdentifier == UNNotificationDismissActionIdentifier {
            // The user dismissed the notification without taking action
        }
        else if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            // The user launched the app
        }
        else if response.notification.request.content.categoryIdentifier == "TIMER_EXPIRED" {
            // Handle the actions for the expired timer.
            if response.actionIdentifier == "SNOOZE_ACTION" {
                // Invalidate the old timer and create a new one. . .
            }
            else if response.actionIdentifier == "STOP_ACTION" {
                // Invalidate the timer. . .
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        print("Device Token:", deviceTokenString)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register:", error)
    }
    
    @available(iOS, deprecated: 10.0)
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        application.registerForRemoteNotifications()
    }
    
    func registerForPushNotifications(application: UIApplication) {
        if #available(iOS 10.0, *) {
            let generalCategory = UNNotificationCategory(identifier: "GENERAL",
                                                         actions: [],
                                                         intentIdentifiers: [],
                                                         options: .customDismissAction)
            
            // Create the custom actions for the TIMER_EXPIRED category.
            let snoozeAction = UNNotificationAction(identifier: "SNOOZE_ACTION",
                                                    title: "Snooze",
                                                    options: UNNotificationActionOptions(rawValue: 0))
            let stopAction = UNNotificationAction(identifier: "STOP_ACTION",
                                                  title: "Stop",
                                                  options: .foreground)
            
            let expiredCategory = UNNotificationCategory(identifier: "TIMER_EXPIRED",
                                                         actions: [snoozeAction, stopAction],
                                                         intentIdentifiers: [],
                                                         options: UNNotificationCategoryOptions(rawValue: 0))
            
            let center = UNUserNotificationCenter.current()
            center.setNotificationCategories([generalCategory, expiredCategory])
            center.delegate = self
            center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
                // Enable or disable features based on authorization.
                guard error == nil else {
                    //Display Error.. Handle Error.. etc..
                    return
                }
                
                if granted {
                    //Do stuff here..
                }
                else {
                    //Handle user denying permissions..
                }
                application.registerForRemoteNotifications()
            }
            
            // For iOS 10 data message (sent via FCM)
            FIRMessaging.messaging().remoteMessageDelegate = self
        } else {
            let notificationSettings = UIUserNotificationSettings(
                types: [.badge, .sound, .alert], categories: nil)
            application.registerUserNotificationSettings(notificationSettings)
        }
    }
    
    func registerLocalNotification() {
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: "Wake up!", arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: "Rise and shine! It's morning time!",
                                                                arguments: nil)
        // Assign the category (and the associated actions).
        content.categoryIdentifier = "TIMER_EXPIRED"
        content.sound = UNNotificationSound.default()
        // Configure the trigger for a 7am wakeup.
        var dateInfo = DateComponents()
        dateInfo.hour = 2
        dateInfo.minute = 44
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: false)
        
        // Create the request object.
        let request = UNNotificationRequest(identifier: "MorningAlarm", content: content, trigger: trigger)
        // Schedule the request.
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error : Error?) in
            if let theError = error {
                print(theError.localizedDescription)
            }
        }
    }
    
    func processNotification() {
        let alertController = UIAlertController(title: "Notification", message: "Long TextCongrats — youve completed this push notifications tutorial and made WenderCast a fully-featured app with push notifications!            You can download the completed project here. Remember that you will still need to change the bundle ID and create certificates to make it work.            Even though push notifications are an important part of apps nowadays, it’s also very common  users to decline permissions to your app  notifications are sent too often. But with thoughtful design, push notifications can keep your users coming back to your app again and again!", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        window?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
}

// [START ios_10_data_message_handling]
extension AppDelegate : FIRMessagingDelegate {
    // Receive data message on iOS 10 devices while app is in the foreground.
    func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
        print(remoteMessage.appData)
    }
}

