import Cocoa
import CoreGraphics

/// Provides screen information for multi-monitor setups
class ScreenInfoProvider {
    
    /// Get information about all connected screens
    func getAllScreens() -> [[String: Any]] {
        var result: [[String: Any]] = []
        
        // Get all screens
        let screens = NSScreen.screens
        
        for (index, screen) in screens.enumerated() {
            let frame = screen.frame
            let isPrimary = (screen == NSScreen.main)
            let scaleFactor = screen.backingScaleFactor
            
            let screenInfo: [String: Any] = [
                "id": index,
                "x": Int(frame.origin.x),
                "y": Int(frame.origin.y),
                "width": Int(frame.width),
                "height": Int(frame.height),
                "isPrimary": isPrimary,
                "scaleFactor": scaleFactor
            ]
            
            result.append(screenInfo)
        }
        
        return result
    }
    
    /// Get primary screen information
    func getPrimaryScreen() -> [String: Any]? {
        guard let mainScreen = NSScreen.main else {
            return nil
        }
        
        let frame = mainScreen.frame
        let scaleFactor = mainScreen.backingScaleFactor
        
        return [
            "id": 0,
            "x": Int(frame.origin.x),
            "y": Int(frame.origin.y),
            "width": Int(frame.width),
            "height": Int(frame.height),
            "isPrimary": true,
            "scaleFactor": scaleFactor
        ]
    }
    
    /// Get screen bounds for a specific screen ID
    func getScreenBounds(screenId: Int) -> CGRect? {
        let screens = NSScreen.screens
        guard screenId < screens.count else {
            return nil
        }
        
        return screens[screenId].frame
    }
}
