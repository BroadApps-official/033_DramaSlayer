import ApphudSDK
import UIKit
import StoreKit
import AppTrackingTransparency
import AdSupport

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var userId: String?
    var orientationLock: UIInterfaceOrientationMask = .portrait

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return orientationLock
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Apphud.start(apiKey: "app_UffEE6pegaQ1THwMyrxDQ1GkEettbk")
        
        let userId = Apphud.userID()
        UserDefaults.standard.set(userId, forKey: "userId")
        
        if #available(iOS 14.5, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    switch status {
                    case .notDetermined:
                        print("notDetermined")
                    case .restricted:
                        print("restricted")
                    case .denied:
                        print("denied")
                    case .authorized:
                        print("authorized")
                        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                    @unknown default:
                        print("@unknown")
                    }
                }
            }
        }

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
