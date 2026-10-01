import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let settingsChannel = FlutterMethodChannel(name: "com.brahvi.keyboard/settings",
                                              binaryMessenger: controller.binaryMessenger)

    let appGroupDefaults = UserDefaults(suiteName: "group.com.brahvi.keyboard")

    settingsChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "syncSettings" {
        if let args = call.arguments as? [String: Any] {
          for (key, val) in args {
            appGroupDefaults?.set(val, forKey: key)
          }
          appGroupDefaults?.synchronize()
          result(true)
        } else {
          result(false)
        }
      } else if call.method == "isKeyboardEnabled" {
        // On iOS, keyboard extensions are enabled by user in iOS Settings > General > Keyboard
        result(true)
      } else if call.method == "openKeyboardSettings" {
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
