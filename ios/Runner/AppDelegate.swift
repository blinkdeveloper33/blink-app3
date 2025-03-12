import Flutter
import UIKit

// Add the AppIconManager implementation directly in this file
class AppIconManager {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.blink_app/app_icon", binaryMessenger: registrar.messenger())
        
        channel.setMethodCallHandler { (call, result) in
            switch call.method {
            case "supportsAlternateIcons":
                result(UIApplication.shared.supportsAlternateIcons)
                
            case "getAlternateIconName":
                result(UIApplication.shared.alternateIconName)
                
            case "setAlternateIconName":
                guard let args = call.arguments as? [String: Any],
                      let iconName = args["iconName"] as? String? else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", 
                                        message: "Arguments are invalid", 
                                        details: nil))
                    return
                }
                
                UIApplication.shared.setAlternateIconName(iconName) { (error) in
                    if let error = error {
                        result(FlutterError(code: "ICON_CHANGE_FAILED", 
                                            message: error.localizedDescription, 
                                            details: nil))
                    } else {
                        result(true)
                    }
                }
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    if let registrar = self.registrar(forPlugin: "AppIconPlugin") {
      AppIconManager.register(with: registrar)
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
