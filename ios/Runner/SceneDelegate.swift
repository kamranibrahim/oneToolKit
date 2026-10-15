import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    super.scene(scene, openURLContexts: URLContexts)
    for context in URLContexts {
      let url = context.url
      if url.scheme == "onetoolkit" && url.host == "share" {
        ShareBridge.notifyShared()
      }
    }
  }
}
