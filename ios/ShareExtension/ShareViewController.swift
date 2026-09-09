import MobileCoreServices
import UniformTypeIdentifiers
import UIKit

final class ShareViewController: UIViewController {
  private let appGroup = "group.com.kamranibrahim.onetoolkit"

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    Task { await handleShare() }
  }

  private func handleShare() async {
    guard
      let items = extensionContext?.inputItems as? [NSExtensionItem]
    else {
      extensionContext?.completeRequest(returningItems: nil)
      return
    }

    var manifest: [[String: String]] = []
    guard let container = FileManager.default
      .containerURL(forSecurityApplicationGroupIdentifier: appGroup)
    else {
      extensionContext?.completeRequest(returningItems: nil)
      return
    }
    let inbox = container.appendingPathComponent("Inbox", isDirectory: true)
    try? FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)

    for item in items {
      guard let attachments = item.attachments else { continue }
      for provider in attachments {
        if let dest = await copy(provider: provider, to: inbox) {
          manifest.append(["name": dest.lastPathComponent, "mime": dest.mime])
        }
      }
    }

    let manifestURL = inbox.appendingPathComponent("manifest.json")
    if let data = try? JSONSerialization.data(withJSONObject: manifest) {
      try? data.write(to: manifestURL)
    }

    openHost()
    extensionContext?.completeRequest(returningItems: nil)
  }

  private struct CopiedFile {
    let lastPathComponent: String
    let mime: String
  }

  private func copy(provider: NSItemProvider, to inbox: URL) async -> CopiedFile? {
    let pdf = UTType.pdf.identifier
    let image = UTType.image.identifier
    let fileURL = UTType.fileURL.identifier
    let type: String
    if provider.hasItemConformingToTypeIdentifier(pdf) {
      type = pdf
    } else if provider.hasItemConformingToTypeIdentifier(image) {
      type = image
    } else if provider.hasItemConformingToTypeIdentifier(fileURL) {
      type = fileURL
    } else {
      return nil
    }

    return await withCheckedContinuation { continuation in
      provider.loadFileRepresentation(forTypeIdentifier: type) { url, _ in
        guard let url else {
          continuation.resume(returning: nil)
          return
        }
        let safe = url.lastPathComponent
          .replacingOccurrences(of: "/", with: "_")
          .replacingOccurrences(of: "\\", with: "_")
        let dest = inbox.appendingPathComponent("\(Int(Date().timeIntervalSince1970))_\(safe)")
        do {
          if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
          }
          try FileManager.default.copyItem(at: url, to: dest)
          let mime = mimeFor(url: dest, typeIdentifier: type)
          continuation.resume(
            returning: CopiedFile(lastPathComponent: dest.lastPathComponent, mime: mime)
          )
        } catch {
          continuation.resume(returning: nil)
        }
      }
    }
  }

  private func mimeFor(url: URL, typeIdentifier: String) -> String {
    if typeIdentifier == UTType.pdf.identifier { return "application/pdf" }
    if let ut = UTType(filenameExtension: url.pathExtension), let mime = ut.preferredMIMEType {
      return mime
    }
    if typeIdentifier == UTType.image.identifier { return "image/jpeg" }
    return "application/octet-stream"
  }

  private func openHost() {
    guard let url = URL(string: "onetoolkit://share") else { return }
    var responder: UIResponder? = self
    while let current = responder {
      if let app = current as? UIApplication {
        app.open(url)
        return
      }
      responder = current.next
    }
    extensionContext?.open(url)
  }
}
