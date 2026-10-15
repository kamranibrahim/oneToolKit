import Flutter
import UIKit

enum ShareBridge {
  static let channelName = "com.kamranibrahim.onetoolkit/share"
  static let appGroup = "group.com.kamranibrahim.onetoolkit"
  static var channel: FlutterMethodChannel?

  private static let queue = DispatchQueue(label: "com.kamranibrahim.onetoolkit.inbox")
  // Paths are acknowledged only after Dart has accepted an existing local copy.

  static func setup(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "takeInbox":
        queue.async {
          let rows = takeInbox()
          DispatchQueue.main.async { result(rows) }
        }
      case "acknowledge":
        let paths = call.arguments as? [String] ?? []
        queue.async {
          ShareInbox.acknowledge(paths)
          DispatchQueue.main.async { result(nil) }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
  }

  static func notifyShared() {
    channel?.invokeMethod("onShared", arguments: nil)
  }

  static func takeInbox() -> [[String: String]] {
    let fm = FileManager.default
    guard let container = fm.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else { return [] }
    return ShareInbox.read(
      at: container.appendingPathComponent("Inbox", isDirectory: true),
      temporaryDirectory: fm.temporaryDirectory)
  }
}

/// File-only inbox logic is independent of Flutter/UI and can be regression tested.
enum ShareInbox {
  private static var awaitingAck: [String: URL] = [:]

  static func read(at inbox: URL, temporaryDirectory: URL) -> [[String: String]] {
    let fm = FileManager.default
    // Legacy flat inbox remains readable during upgrades.
    var batches = [inbox]
    let children = (try? fm.contentsOfDirectory(at: inbox,
      includingPropertiesForKeys: [.isDirectoryKey, .creationDateKey])) ?? []
    batches += children.filter {
      (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }.sorted {
      let left = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
      let right = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
      return left == right ? $0.lastPathComponent < $1.lastPathComponent : left < right
    }
    var out: [[String: String]] = []
    for batch in batches {
      let manifestURL = batch.appendingPathComponent("manifest.json")
      guard let data = try? Data(contentsOf: manifestURL),
        let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else { continue }
      for row in rows {
        guard let name = row["name"], !name.isEmpty,
          name == (name as NSString).lastPathComponent, name != ".", name != ".." else { continue }
        let source = batch.appendingPathComponent(name)
        guard fm.fileExists(atPath: source.path) else { continue }
        // Stable destination makes an unacknowledged delivery safe to retry.
        let dest = temporaryDirectory.appendingPathComponent("share_\(name)")
        do {
          if !fm.fileExists(atPath: dest.path) {
            let partial = temporaryDirectory.appendingPathComponent(UUID().uuidString)
            do {
              try fm.copyItem(at: source, to: partial)
              try fm.moveItem(at: partial, to: dest)
            } catch {
              try? fm.removeItem(at: partial)
              throw error
            }
          }
          awaitingAck[dest.path] = source
          out.append(["path": dest.path, "mime": row["mime"] ?? "application/octet-stream"])
        } catch {
          // Keep the source and manifest for the next intake attempt.
          out.append(["error": "Some shared files could not be imported. Tap Review to retry."])
          continue
        }
      }
    }
    return out
  }

  static func acknowledge(_ paths: [String]) {
    let fm = FileManager.default
    for path in paths {
      guard let source = awaitingAck[path], fm.fileExists(atPath: path) else { continue }
      do {
        try fm.removeItem(at: source)
        awaitingAck.removeValue(forKey: path)
        let batch = source.deletingLastPathComponent()
        let contents = try fm.contentsOfDirectory(at: batch, includingPropertiesForKeys: nil)
        if contents.allSatisfy({ $0.lastPathComponent == "manifest.json" }) {
          try? fm.removeItem(at: batch.appendingPathComponent("manifest.json"))
          if batch.lastPathComponent != "Inbox" { try? fm.removeItem(at: batch) }
        }
      } catch {
        // Source stays retryable if acknowledgment cleanup fails.
      }
    }
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
    let saved = FlutterMethodChannel(name: "com.kamranibrahim.onetoolkit/saved_work",
      binaryMessenger: engineBridge.applicationRegistrar.messenger())
    saved.setMethodCallHandler { call, result in
      guard call.method == "directory" else { result(FlutterMethodNotImplemented); return }
      do {
        let support = try FileManager.default.url(for: .applicationSupportDirectory,
          in: .userDomainMask, appropriateFor: nil, create: true)
        var directory = support.appendingPathComponent("SavedWork", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
          attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try directory.setResourceValues(values)
        result(directory.path)
      } catch { result(FlutterError(code: "storage", message: "Private saved storage is unavailable", details: nil)) }
    }
  }
}
