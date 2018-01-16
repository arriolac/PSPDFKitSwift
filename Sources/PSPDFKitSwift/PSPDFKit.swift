import PSPDFKit

extension PSPDFKitObject {

    /// Allow direct dictionary-like access.
    public subscript(key: String) -> Any? {
        get {
            return __objectForKeyedSubscript(key as NSString)
        }
        set {
            guard let newValue = newValue else { return }
            __setObject(newValue, forKeyedSubscript: key as NSString)
        }
    }

    /**
     Custom log handler to forward logging to a different system.

     PSPDFKit uses `os_log` or falls back to `NSLog` on older OS versions (iOS 9)
     Setting this to NULL will reset the default behavior.

     @note Usage example:
     ```
     PSPDFKit.sharedInstance.setLogHandler { (level: PSPDFLogLevelMask, tag: String, message: @escaping () -> String, file: String, function: String, line: Int) in
        print("PSPDFKit says from \(function): \(message())");
     }
     ```
     */
    public func setLogHandler(handler: @escaping (_ level: PSPDFLogLevelMask, _ tag: String, _ message: @escaping () -> String, _ file: String, _ function: String, _ line: Int) -> Void) -> Void {
        self.logHandler = handler
    }

    private var logHandler: ((_ level: PSPDFLogLevelMask, _ tag: String, _ message: @escaping () -> String, _ file: String, _ function: String, _ line: Int) -> Void) {
        get {
            return { [unowned self] (level: PSPDFLogLevelMask, tag: String, message: @escaping () -> String, file: String, function: String, line: Int) in
                tag.withCString { tagPointer in
                    file.withCString { filePointer in
                        function.withCString { functionPointer in
                            self.__logHandler(level, tagPointer, message, filePointer, functionPointer, UInt(line))
                        }
                    }
                }
            }
        }
        set {
            __logHandler = { (type: PSPDFLogLevelMask, tag: UnsafePointer<Int8>?, message: () -> String, file: UnsafePointer<Int8>, function: UnsafePointer<Int8>, line: UInt) in
                newValue(type, tag == nil ? "" : String(cString: tag!), message, String(cString: file), String(cString: function), Int(line))
            }
        }
    }
}

internal class PSPDFKitObjectTests {
    static func test() throws {
        // let any = PSPDFKitOrigin.shared["foo" as NSCopying] // Any?
        // PSPDFKitOrigin.shared.setObject(1 as NSNumber, forKeyedSubscript: "foo" as NSCopying)
        // PSPDFKit.sharedInstance.logLevel = [.debug]
        PSPDFKit.sharedInstance.setLogHandler { (level: PSPDFLogLevelMask, tag: String, message: @escaping () -> String, file: String, function: String, line: Int) in
            print("PSPDFKit says from \(function): \(message())");
        }
        PSPDFKit.sharedInstance["abc"] = 1
        let value = PSPDFKit.sharedInstance["abc"] as? Int
        guard value == 1 else { throw NSError.pspdf_error(withCode: 0, description: "Invalid value") }
    }
}