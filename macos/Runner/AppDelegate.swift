import Cocoa
import FlutterMacOS
import IOKit.pwr_mgt

@main
class AppDelegate: FlutterAppDelegate {
  private var assertionID: IOPMAssertionID = 0
  private var assertionActive = false

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
      return
    }

    let sleepChannel = FlutterMethodChannel(
      name: "desktop_cat/sleep_preventer",
      binaryMessenger: controller.engine.binaryMessenger
    )
    sleepChannel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "enable":
        self?.enableDisplayWake()
        result(nil)
      case "disable":
        self?.disableDisplayWake()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let idleChannel = FlutterMethodChannel(
      name: "desktop_cat/idle_detector",
      binaryMessenger: controller.engine.binaryMessenger
    )
    idleChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "idleSeconds":
        let anyInputEvent = CGEventType(rawValue: UInt32.max)!
        result(Int(CGEventSource.secondsSinceLastEventType(
          .combinedSessionState,
          eventType: anyInputEvent
        )))
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.applicationDidFinishLaunching(notification)
  }

  private func enableDisplayWake() {
    guard !assertionActive else { return }
    let reason = "Desktop Cat is keeping the display awake" as CFString
    let status = IOPMAssertionCreateWithName(
      kIOPMAssertionTypeNoDisplaySleep as CFString,
      IOPMAssertionLevel(kIOPMAssertionLevelOn),
      reason,
      &assertionID
    )
    assertionActive = status == kIOReturnSuccess
  }

  private func disableDisplayWake() {
    guard assertionActive else { return }
    IOPMAssertionRelease(assertionID)
    assertionActive = false
  }
}
