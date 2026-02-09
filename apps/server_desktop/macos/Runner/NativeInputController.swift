import Cocoa
import CoreGraphics

/// Native input controller for macOS using Core Graphics events
class NativeInputController {
    
    /// Move mouse cursor relatively
    func moveMouse(dx: Double, dy: Double) -> Bool {
        // Get current mouse location
        let currentLocation = NSEvent.mouseLocation
        
        // Calculate new position (accounting for flipped coordinate system)
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let currentY = screenHeight - currentLocation.y
        let newX = currentLocation.x + CGFloat(dx)
        let newY = currentY + CGFloat(dy)
        
        // Create and post mouse move event
        if let event = CGEvent(mouseEventSource: nil,
                             mouseType: .mouseMoved,
                             mouseCursorPosition: CGPoint(x: newX, y: newY),
                             mouseButton: .left) {
            event.post(tap: .cghidEventTap)
            return true
        }
        
        return false
    }
    
    /// Move mouse to absolute position
    func moveMouseAbsolute(x: Int, y: Int) -> Bool {
        if let event = CGEvent(mouseEventSource: nil,
                             mouseType: .mouseMoved,
                             mouseCursorPosition: CGPoint(x: x, y: y),
                             mouseButton: .left) {
            event.post(tap: .cghidEventTap)
            return true
        }
        return false
    }
    
    /// Perform mouse click
    func clickMouse(button: String, action: String, x: Int? = nil, y: Int? = nil) -> Bool {
        // Determine button type and event types
        let (mouseButton, downType, upType): (CGMouseButton, CGEventType, CGEventType)
        
        switch button {
        case "left":
            mouseButton = .left
            downType = .leftMouseDown
            upType = .leftMouseUp
        case "right":
            mouseButton = .right
            downType = .rightMouseDown
            upType = .rightMouseUp
        case "middle":
            mouseButton = .center
            downType = .otherMouseDown
            upType = .otherMouseUp
        default:
            return false
        }
        
        // Get current position or use provided position
        let position: CGPoint
        if let x = x, let y = y {
            position = CGPoint(x: x, y: y)
        } else {
            position = CGEvent(source: nil)?.location ?? .zero
        }
        
        // Perform action
        switch action {
        case "down":
            if let event = CGEvent(mouseEventSource: nil,
                                 mouseType: downType,
                                 mouseCursorPosition: position,
                                 mouseButton: mouseButton) {
                event.post(tap: .cghidEventTap)
                return true
            }
        case "up":
            if let event = CGEvent(mouseEventSource: nil,
                                 mouseType: upType,
                                 mouseCursorPosition: position,
                                 mouseButton: mouseButton) {
                event.post(tap: .cghidEventTap)
                return true
            }
        case "double":
            // Perform double click
            if let downEvent = CGEvent(mouseEventSource: nil,
                                     mouseType: downType,
                                     mouseCursorPosition: position,
                                     mouseButton: mouseButton),
               let upEvent = CGEvent(mouseEventSource: nil,
                                   mouseType: upType,
                                   mouseCursorPosition: position,
                                   mouseButton: mouseButton) {
                downEvent.setIntegerValueField(.mouseEventClickState, value: 1)
                downEvent.post(tap: .cghidEventTap)
                upEvent.setIntegerValueField(.mouseEventClickState, value: 1)
                upEvent.post(tap: .cghidEventTap)
                
                // Second click
                downEvent.setIntegerValueField(.mouseEventClickState, value: 2)
                downEvent.post(tap: .cghidEventTap)
                upEvent.setIntegerValueField(.mouseEventClickState, value: 2)
                upEvent.post(tap: .cghidEventTap)
                return true
            }
        default:
            return false
        }
        
        return false
    }
    
    /// Perform scroll
    func scroll(dx: Double, dy: Double, isPrecise: Bool) -> Bool {
        // Create scroll event
        if let event = CGEvent(scrollWheelEvent2Source: nil,
                             units: isPrecise ? .pixel : .line,
                             wheelCount: 2,
                             wheel1: Int32(dy),
                             wheel2: Int32(dx),
                             wheel3: 0) {
            event.post(tap: .cghidEventTap)
            return true
        }
        return false
    }
    
    /// Press keyboard key
    func pressKey(key: String, modifiers: [String], action: String) -> Bool {
        guard let keyCode = getKeyCode(for: key) else {
            return false
        }
        
        let isDown = action == "down"
        
        // Build modifier flags
        var flags: CGEventFlags = []
        for modifier in modifiers {
            switch modifier {
            case "cmd", "command":
                flags.insert(.maskCommand)
            case "shift":
                flags.insert(.maskShift)
            case "ctrl", "control":
                flags.insert(.maskControl)
            case "alt", "opt", "option":
                flags.insert(.maskAlternate)
            default:
                break
            }
        }
        
        // Create key event
        if let event = CGEvent(keyboardEventSource: nil,
                             virtualKey: keyCode,
                             keyDown: isDown) {
            event.flags = flags
            event.post(tap: .cghidEventTap)
            return true
        }
        
        return false
    }
    
    /// Type text (bulk input)
    func typeText(text: String) -> Bool {
        for char in text {
            let charString = String(char)
            // Use text input event for more reliable text entry
            if let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) {
                event.keyboardSetUnicodeString(stringLength: charString.utf16.count,
                                             unicodeString: Array(charString.utf16))
                event.post(tap: .cghidEventTap)
                
                // Key up event
                if let upEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) {
                    upEvent.keyboardSetUnicodeString(stringLength: charString.utf16.count,
                                                   unicodeString: Array(charString.utf16))
                    upEvent.post(tap: .cghidEventTap)
                }
            }
        }
        return true
    }
    
    /// Get virtual key code for key name
    private func getKeyCode(for key: String) -> CGKeyCode? {
        let keyCodeMap: [String: CGKeyCode] = [
            "a": 0x00, "s": 0x01, "d": 0x02, "f": 0x03, "h": 0x04, "g": 0x05, "z": 0x06, "x": 0x07,
            "c": 0x08, "v": 0x09, "b": 0x0B, "q": 0x0C, "w": 0x0D, "e": 0x0E, "r": 0x0F, "y": 0x10,
            "t": 0x11, "1": 0x12, "2": 0x13, "3": 0x14, "4": 0x15, "6": 0x16, "5": 0x17, "=": 0x18,
            "9": 0x19, "7": 0x1A, "-": 0x1B, "8": 0x1C, "0": 0x1D, "]": 0x1E, "o": 0x1F, "u": 0x20,
            "[": 0x21, "i": 0x22, "p": 0x23, "l": 0x25, "j": 0x26, "'": 0x27, "k": 0x28, ";": 0x29,
            "\\": 0x2A, ",": 0x2B, "/": 0x2C, "n": 0x2D, "m": 0x2E, ".": 0x2F, "`": 0x32,
            "space": 0x31, "return": 0x24, "enter": 0x4C, "tab": 0x30, "delete": 0x33, "backspace": 0x33,
            "escape": 0x35, "esc": 0x35,
            "f1": 0x7A, "f2": 0x78, "f3": 0x63, "f4": 0x76, "f5": 0x60, "f6": 0x61,
            "f7": 0x62, "f8": 0x64, "f9": 0x65, "f10": 0x6D, "f11": 0x67, "f12": 0x6F,
            "left": 0x7B, "right": 0x7C, "down": 0x7D, "up": 0x7E,
            "home": 0x73, "end": 0x77, "pageup": 0x74, "pagedown": 0x79
        ]
        
        return keyCodeMap[key.lowercased()]
    }
}
