import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private let inputController = NativeInputController()
  private let screenInfoProvider = ScreenInfoProvider()
  private let accessibilityManager = AccessibilityManager()
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    let controller : FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.remoteforpc.input",
                                      binaryMessenger: controller.engine.binaryMessenger)
    
    channel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      guard let self = self else { return }
      
      switch call.method {
      case "moveMouse":
        if let args = call.arguments as? [String: Any],
           let dx = args["dx"] as? Double,
           let dy = args["dy"] as? Double {
          let success = self.inputController.moveMouse(dx: dx, dy: dy)
          result(success)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
        
      case "moveMouseAbsolute":
        if let args = call.arguments as? [String: Any],
           let x = args["x"] as? Int,
           let y = args["y"] as? Int {
          let success = self.inputController.moveMouseAbsolute(x: x, y: y)
          result(success)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
        
      case "clickMouse":
        if let args = call.arguments as? [String: Any],
           let button = args["button"] as? String,
           let action = args["action"] as? String {
          let x = args["x"] as? Int
          let y = args["y"] as? Int
          let success = self.inputController.clickMouse(button: button, action: action, x: x, y: y)
          result(success)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
        
      case "scroll":
        if let args = call.arguments as? [String: Any],
           let dx = args["dx"] as? Double,
           let dy = args["dy"] as? Double {
          let isPrecise = args["isPrecise"] as? Bool ?? true
          let success = self.inputController.scroll(dx: dx, dy: dy, isPrecise: isPrecise)
          result(success)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
        
      case "pressKey":
        if let args = call.arguments as? [String: Any],
           let key = args["key"] as? String,
           let modifiers = args["modifiers"] as? [String],
           let action = args["action"] as? String {
          let success = self.inputController.pressKey(key: key, modifiers: modifiers, action: action)
          result(success)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
        
      case "typeText":
        if let args = call.arguments as? [String: Any],
           let text = args["text"] as? String {
          let success = self.inputController.typeText(text: text)
          result(success)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
        
      case "getScreenInfo":
        let screens = self.screenInfoProvider.getAllScreens()
        result(screens)
        
      case "getPrimaryScreen":
        if let screen = self.screenInfoProvider.getPrimaryScreen() {
          result(screen)
        } else {
          result(FlutterError(code: "NO_SCREEN", message: "No primary screen found", details: nil))
        }
        
      case "checkAccessibility":
        let hasAccess = self.accessibilityManager.checkAccessibility()
        result(hasAccess)
        
      case "requestAccessibility":
        let hasAccess = self.accessibilityManager.requestAccessibility()
        result(hasAccess)
        
      case "openAccessibilityPreferences":
        self.accessibilityManager.openAccessibilityPreferences()
        result(true)
        
      default:
        result(FlutterMethodNotImplemented)
      }
    })
  }
  
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false  // Changed to false to allow system tray functionality
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}

