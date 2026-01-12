import Foundation
// import FirebaseAnalytics // Commented out until added via SPM

class AnalyticsService {
    static let shared = AnalyticsService()
    
    private init() {}
    
    func log(_ eventName: String, params: [String: Any]? = nil) {
        // Implementation note: When Firebase is added, uncomment the line below.
        // Analytics.logEvent(eventName, parameters: params)
        
        #if DEBUG
        print("[Analytics] \(eventName): \(String(describing: params))")
        #endif
    }
    
    // Strongly typed events
    func logAppOpen() {
        log("app_open")
    }
    
    func logPermissionPrompt(shown: Bool) {
        log("permission_prompt_shown")
    }
    
    func logPermissionGranted(full: Bool) {
        log("permission_granted", params: ["type": full ? "full" : "limited"])
    }
    
    func logFeedOpened(type: String) {
        log("feed_opened", params: ["feed_type": type])
    }
    
    func logSwipe(keep: Bool, feedType: String) {
        log(keep ? "swipe_keep" : "swipe_delete", params: ["feed_type": feedType])
    }
    
    func logUndo() {
        log("undo_tapped")
    }
}
