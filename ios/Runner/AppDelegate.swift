import Flutter
import UIKit
import Contacts

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var contactsChannel: FlutterMethodChannel?
  private var channelReady = false

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
    if !channelReady {
      setupContactsChannel()
    }
  }

  // MARK: - Channel 初始化

  private func setupContactsChannel() {
    guard !channelReady else { return }
    guard let controller = window?.rootViewController as? FlutterViewController,
          let messenger = controller.binaryMessenger as? FlutterBinaryMessenger
    else { return }

    let channel = FlutterMethodChannel(
      name: "com.example.helloChina/contacts",
      binaryMessenger: messenger)
    contactsChannel = channel
    channelReady = true

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
