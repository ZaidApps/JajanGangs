import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var notificationPlayer: AVAudioPlayer?
  private var soundChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "JajanNotificationSound") else { return }
    let key = registrar.lookupKey(forAsset: "assets/audio/jajan_chime.wav")
    soundChannel = FlutterMethodChannel(name: "jajangangs/notification_sound", binaryMessenger: registrar.messenger())
    soundChannel?.setMethodCallHandler { [weak self] call, result in
      guard call.method == "play" else { result(FlutterMethodNotImplemented); return }
      guard UIApplication.shared.applicationState == .active else { result(nil); return }
      do {
        // Ambient respects the silent switch and mixes with other audio.
        try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        if self?.notificationPlayer == nil, let url = Bundle.main.url(forResource: key, withExtension: nil) {
          self?.notificationPlayer = try AVAudioPlayer(contentsOf: url)
          self?.notificationPlayer?.volume = 0.65
        }
        self?.notificationPlayer?.currentTime = 0
        self?.notificationPlayer?.play()
      } catch { /* Keep notification delivery independent of audio availability. */ }
      result(nil)
    }
  }
}
