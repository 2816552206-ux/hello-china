import Flutter
import UIKit
import Contacts

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
    ContactsPlugin.register(
      with: engineBridge.pluginRegistry,
      messenger: engineBridge.binaryMessenger)
  }
}

// ========== 通讯录插件 ==========

class ContactsPlugin: NSObject, FlutterPlugin {
  private var channel: FlutterMethodChannel?

  static func register(with registry: FlutterPluginRegistry, messenger: FlutterBinaryMessenger) {
    let instance = ContactsPlugin()
    let ch = FlutterMethodChannel(
      name: "com.example.helloChina/contacts",
      binaryMessenger: messenger)
    instance.channel = ch
    registry.addMethodCallDelegate(instance, channel: ch)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getContacts":
      fetchContacts(result: result)
    case "requestPermission":
      requestPermission(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func detachFromEngine(for registry: FlutterPluginRegistry) {
    channel?.setMethodCallHandler(nil)
    channel = nil
  }

  // MARK: - 权限请求

  private func requestPermission(result: @escaping FlutterResult) {
    let store = CNContactStore()
    store.requestAccess(for: .contacts) { granted, error in
      if let error = error {
        result(FlutterError(code: "PERMISSION_ERROR",
                            message: error.localizedDescription, details: nil))
      } else {
        result(granted)
      }
    }
  }

  // MARK: - 读取通讯录

  private func fetchContacts(result: @escaping FlutterResult) {
    let store = CNContactStore()
    let keys: [CNKeyDescriptor] = [
      CNContactGivenNameKey as CNKeyDescriptor,
      CNContactFamilyNameKey as CNKeyDescriptor,
      CNContactPhoneNumbersKey as CNKeyDescriptor,
      CNContactOrganizationNameKey as CNKeyDescriptor
    ]
    let request = CNContactFetchRequest(keysToFetch: keys)

    DispatchQueue.global(qos: .userInitiated).async {
      var contacts: [[String: Any]] = []
      do {
        try store.enumerateContacts(with: request) { contact, _ in
          var dict: [String: Any] = [:]
          let given = contact.givenName
          let family = contact.familyName
          dict["givenName"] = given
          dict["familyName"] = family
          dict["displayName"] = "\(given) \(family)".trimmingCharacters(in: .whitespaces)
          dict["organization"] = contact.organizationName
          dict["phones"] = contact.phoneNumbers.map { $0.value.stringValue }
          contacts.append(dict)
        }
        DispatchQueue.main.async {
          result(contacts)
        }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "FETCH_ERROR",
                              message: error.localizedDescription, details: nil))
        }
      }
    }
  }
}
