"""Run the production Foundation-only inbox reader on macOS, without Flutter.

Usage: python3 test/native/run_share_inbox_tests.py
"""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
source = (root / 'ios/Runner/AppDelegate.swift').read_text()
inbox = source.split('enum ShareInbox {', 1)[1].split('\n@main', 1)[0]
checks = r'''
let fm = FileManager.default
let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
let inbox = root.appendingPathComponent("Inbox")
let output = root.appendingPathComponent("Output")
try fm.createDirectory(at: inbox, withIntermediateDirectories: true)
try fm.createDirectory(at: output, withIntermediateDirectories: true)
defer { try? fm.removeItem(at: root) }

func publish(_ batch: String, _ names: [String]) throws -> URL {
  let dir = inbox.appendingPathComponent(batch)
  try fm.createDirectory(at: dir, withIntermediateDirectories: true)
  let rows = try names.map { name -> [String: String] in
    try Data(name.utf8).write(to: dir.appendingPathComponent(name))
    return ["name": name, "mime": "application/pdf"]
  }
  try JSONSerialization.data(withJSONObject: rows).write(to: dir.appendingPathComponent("manifest.json"), options: .atomic)
  return dir
}
func delivered(_ rows: [[String: String]]) -> [String] { rows.compactMap { $0["path"] } }

let batch = try publish("batch-one", ["unique-z_report.pdf", "unique-a_report.pdf"])
let first = ShareInbox.read(at: inbox, temporaryDirectory: output)
let paths = delivered(first)
precondition(paths.count == 2)
precondition(paths.map { URL(fileURLWithPath: $0).lastPathComponent } == ["share_unique-z_report.pdf", "share_unique-a_report.pdf"], "Manifest attachment order must be retained")
precondition(fm.fileExists(atPath: batch.appendingPathComponent("unique-z_report.pdf").path), "Reading must not delete sources")
precondition(delivered(ShareInbox.read(at: inbox, temporaryDirectory: output)) == paths, "Redelivery uses stable paths")
let copiedBytes = try Data(contentsOf: URL(fileURLWithPath: paths[0]))
precondition(copiedBytes == Data("unique-z_report.pdf".utf8))
ShareInbox.acknowledge([paths[0]])
precondition(!fm.fileExists(atPath: batch.appendingPathComponent("unique-z_report.pdf").path))
precondition(fm.fileExists(atPath: batch.appendingPathComponent("unique-a_report.pdf").path))
precondition(delivered(ShareInbox.read(at: inbox, temporaryDirectory: output)) == [paths[1]])
ShareInbox.acknowledge([paths[1]])
precondition(!fm.fileExists(atPath: batch.path), "Only a fully acknowledged batch is cleaned up")
precondition(fm.fileExists(atPath: paths[0]), "Accepted local copies remain usable")
print("PASS ordered intake, stable redelivery, partial acknowledgment, batch cleanup")

let retryBatch = try publish("batch-retry", ["unique_retry.pdf"])
let blockedOutput = root.appendingPathComponent("not-a-directory")
try Data("blocked".utf8).write(to: blockedOutput)
let failed = ShareInbox.read(at: inbox, temporaryDirectory: blockedOutput)
precondition(delivered(failed).isEmpty && failed.contains { $0["error"] != nil })
precondition(fm.fileExists(atPath: retryBatch.appendingPathComponent("unique_retry.pdf").path))
let retried = delivered(ShareInbox.read(at: inbox, temporaryDirectory: output))
precondition(retried.count == 1)
ShareInbox.acknowledge(retried)
print("PASS failed copy retains source and can retry")

let incomplete = inbox.appendingPathComponent("incomplete")
try fm.createDirectory(at: incomplete, withIntermediateDirectories: true)
try Data("not published".utf8).write(to: incomplete.appendingPathComponent("input.pdf"))
precondition(delivered(ShareInbox.read(at: inbox, temporaryDirectory: output)).isEmpty)
try Data("legacy".utf8).write(to: inbox.appendingPathComponent("legacy.pdf"))
try JSONSerialization.data(withJSONObject: [["name": "../outside.pdf", "mime": "application/pdf"], ["name": "legacy.pdf", "mime": "application/pdf"]]).write(to: inbox.appendingPathComponent("manifest.json"))
let legacy = delivered(ShareInbox.read(at: inbox, temporaryDirectory: output))
precondition(legacy.count == 1 && legacy[0].hasSuffix("share_legacy.pdf"))
ShareInbox.acknowledge([root.appendingPathComponent("unknown").path])
precondition(fm.fileExists(atPath: inbox.appendingPathComponent("legacy.pdf").path))
ShareInbox.acknowledge(legacy)
precondition(fm.fileExists(atPath: incomplete.appendingPathComponent("input.pdf").path))
print("PASS legacy manifest, invalid names, incomplete batch and unknown acknowledgment")
'''
# Compile the actual enum from the host source; no copy of its implementation.
with tempfile.TemporaryDirectory(prefix='onetoolkit-inbox-test-') as directory:
    main = Path(directory) / 'main.swift'
    main.write_text('import Foundation\nenum ShareInbox {' + inbox + '\n' + checks)
    binary = Path(directory) / 'inbox-tests'
    subprocess.run(['xcrun', 'swiftc', str(main), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
