import Flutter
import UIKit

enum ShareBridge {
  static let channelName = "com.kamranibrahim.onetoolkit/share"
  static let appGroup = "group.com.kamranibrahim.onetoolkit"
  static var channel: FlutterMethodChannel?

  static func setup(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      if call.method == "takeInbox" {
        result(takeInbox())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
  }

  static func notifyShared() {
    channel?.invokeMethod("onShared", arguments: nil)
  }

  /// Copy App Group Inbox files into the app temp dir, then delete Inbox.
  static func takeInbox() -> [[String: String]] {
    guard
      let container = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: appGroup
      )
    else {
      return []
    }
    let inbox = container.appendingPathComponent("Inbox", isDirectory: true)
    let manifestURL = inbox.appendingPathComponent("manifest.json")
    var mimeByName: [String: String] = [:]
    if let data = try? Data(contentsOf: manifestURL),
       let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: String]]
    {
      for row in rows {
        if let name = row["name"], let mime = row["mime"] {
          mimeByName[name] = mime
        }
      }
    }

    var out: [[String: String]] = []
    let files = (try? FileManager.default.contentsOfDirectory(
      at: inbox,
      includingPropertiesForKeys: nil
    )) ?? []
    for url in files {
      if url.lastPathComponent == "manifest.json" { continue }
      let dest = FileManager.default.temporaryDirectory
        .appendingPathComponent("share_\(Int(Date().timeIntervalSince1970))_\(url.lastPathComponent)")
      do {
        if FileManager.default.fileExists(atPath: dest.path) {
          try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.copyItem(at: url, to: dest)
        let mime = mimeByName[url.lastPathComponent] ?? "application/octet-stream"
        out.append(["path": dest.path, "mime": mime])
      } catch {
        continue
      }
    }
    try? FileManager.default.removeItem(at: inbox)
    return out
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    ShareBridge.setup(messenger: engineBridge.applicationRegistrar.messenger())
  }
}
