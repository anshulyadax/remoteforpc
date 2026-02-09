import Cocoa
import ApplicationServices

/// Manages accessibility permissions required for input injection
class AccessibilityManager {
    
    /// Check if app has accessibility permissions
    func checkAccessibility() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    /// Request accessibility permissions (shows system dialog)
    func requestAccessibility() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    /// Open System Preferences to accessibility pane
    func openAccessibilityPreferences() {
        if #available(macOS 13.0, *) {
            // macOS Ventura and later
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        } else {
            // macOS Monterey and earlier
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
    }
}
