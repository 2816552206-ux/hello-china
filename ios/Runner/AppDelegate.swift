import Flutter
import UIKit
import Contacts

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var contactsChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    setupChannelOnce()
  }

  // MARK: - Channel

  private func setupChannelOnce() {
    guard contactsChannel == nil,
          let controller = window?.rootViewController as? FlutterViewController
    else { return }

    let channel = FlutterMethodChannel(
      name: "com.example.helloChina/contacts",
      binaryMessenger: controller.binaryMessenger)
    contactsChannel = channel

    channel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "getContacts":
        self?.fetchContacts(result: result)
      case "requestPermission":
        self?.requestPermission(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - 权限

  private func requestPermission(result: @escaping FlutterResult) {
    CNContactStore().requestAccess(for: .contacts) { granted, error in
      if let error = error {
        result(FlutterError(code: "PERMISSION_ERROR",
                            message: error.localizedDescription, details: nil))
      } else {
        result(granted)
      }
    }
  }

  // MARK: - 通讯录

  private func fetchContacts(result: @escaping FlutterResult) {
    let store = CNContactStore()
    let keys: [CNKeyDescriptor] = [
      CNContactGivenNameKey as CNKeyDescriptor,
      CNContactFamilyNameKey as CNKeyDescriptor,
      CNContactPhoneNumbersKey as CNKeyDescriptor
    ]
    let request = CNContactFetchRequest(keysToFetch: keys)
    DispatchQueue.global(qos: .userInitiated).async {
      var list: [[String: Any]] = []
      do {
        try store.enumerateContacts(with: request) { contact, _ in
          list.append([
            "givenName": contact.givenName,
            "familyName": contact.familyName,
            "displayName": "\(contact.givenName) \(contact.familyName)"
              .trimmingCharacters(in: .whitespaces),
            "phones": contact.phoneNumbers.map { $0.value.stringValue }
          ])
        }
        DispatchQueue.main.async { result(list) }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "FETCH_ERROR",
                              message: error.localizedDescription, details: nil))
        }
      }
    }
  }
}
