import UIKit
import Flutter
import Foundation
import WalletConnectSwift


@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let walletChannel = FlutterMethodChannel(name: "samples.flutter.dev/walletConnect",
                                              binaryMessenger: controller.binaryMessenger)
        walletChannel.setMethodCallHandler {(call: FlutterMethodCall, result: FlutterResult) -> Void in
            if (call.method == "connectToWallet") {
                    MainViewController().connect()
                }
            if (call.method == "getAccount"){
                MainViewController().getAccount(result: result)
            }
        }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

protocol WalletConnectDelegate {
    func failedToConnect()
    func didConnect()
    func didDisconnect()
}

class MainViewController: ClientDelegate {
    
    func onMainThread(_ closure: @escaping () -> Void) {
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.async {
                closure()
            }
        }
    }
    
    func client(_ client: Client, didFailToConnect url: WCURL) {
            delegate.failedToConnect()
        }

        func client(_ client: Client, didConnect url: WCURL) {
            // do nothing
        }

        func client(_ client: Client, didConnect session: Session) {
            self.session = session
            let sessionData = try! JSONEncoder().encode(session)
            UserDefaults.standard.set(sessionData, forKey: sessionKey)
            delegate.didConnect()
        }

        func client(_ client: Client, didDisconnect session: Session) {
            UserDefaults.standard.removeObject(forKey: sessionKey)
            delegate.didDisconnect()
        }

        func client(_ client: Client, didUpdate session: Session) {
            // do nothing
        }
    
 
    
    var delegate: WalletConnectDelegate!
    var client: Client!
    var session: Session!
    
    var sessionKey = "sessionKey"

    
    func connectWallet() -> String {
        // gnosis wc bridge: https://safe-walletconnect.gnosis.io/
        // test bridge with latest protocol version: https://bridge.walletconnect.org
        let wcUrl =  WCURL(topic: UUID().uuidString,
                           bridgeURL: URL(string: "https://safe-walletconnect.gnosis.io/")!,
                           key: try! randomKey())
        let clientMeta = Session.ClientMeta(name: "MyApplication",
                                            description: "WalletConnectSwift ",
                                            icons: [],
                                            url: URL(string: "https://safe.gnosis.io")!)
        let dAppInfo = Session.DAppInfo(peerId: UUID().uuidString, peerMeta: clientMeta)
        client = Client(delegate: self, dAppInfo: dAppInfo)

        print("WalletConnect URL: \(wcUrl.absoluteString)")

        try! client.connect(to: wcUrl)
        return wcUrl.absoluteString
    }


    func connect() {
        let connectionUrl = connectWallet()
        //let deepLinkUrl = "https://metamask.app.link/wc?uri=\(connectionUrl)"
    

        if let url = URL(string: connectionUrl), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            print("error")
        }
    }
    
    func getAccount(result: FlutterResult){
        let accountId = AppData.shared.accounts;
        print(accountId)
        result(accountId)
    }
    
    private func randomKey() throws -> String {
        var bytes = [Int8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if status == errSecSuccess {
            return Data(bytes: bytes, count: 32).toHexString()
        } else {
            // we don't care in the example app
            enum TestError: Error {
                case unknown
            }
            throw TestError.unknown
        }
    }
}

extension MainViewController: WalletConnectDelegate {
    func failedToConnect() {
        onMainThread { [unowned self] in
//            if let handshakeController = self.handshakeController {
//                handshakeController.dismiss(animated: true)
//            }
//            UIAlertController.showFailedToConnect(from: self)
            print("failed");
        }
    }

    func didConnect() {
        onMainThread { [unowned self] in
//            self.actionsController = ActionsViewController.create(walletConnect: self.walletConnect)
//            if let handshakeController = self.handshakeController {
//                handshakeController.dismiss(animated: false) { [unowned self] in
//                    self.present(self.actionsController, animated: false)
//                }
//            } else if self.presentedViewController == nil {
//                self.present(self.actionsController, animated: false)
//            }
            print("connected");
        }
    }

    func didDisconnect() {
        onMainThread { [unowned self] in
//            if let presented = self.presentedViewController {
//                presented.dismiss(animated: false)
//            }
//            UIAlertController.showDisconnected(from: self)
            print("disconnect");
        }
    }
}

class AppData {
    static let shared = AppData()
    
    private init() {}
    
    var peerId: String {
        get{
            UserDefaults.standard.string(forKey: "peerId") ?? ""
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "peerId")
        }
    }
    
    var accounts: [Any] {
        get{
            UserDefaults.standard.array(forKey: "accounts") ?? []
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "accounts")
        }
    }
    
    private let userNotificationCenter = UNUserNotificationCenter.current()

    func requestNotificationAuthorization() {
        let authOptions = UNAuthorizationOptions.init(arrayLiteral: .alert, .badge, .sound)
        
        self.userNotificationCenter.requestAuthorization(options: authOptions) { (success, error) in
            if let error = error {
                print("Error: ", error)
            }
        }
    }

    func sendNotification(title: String, body: String) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = title
        notificationContent.body = body
        notificationContent.badge = NSNumber(value: 3)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2,
                                                        repeats: false)
        let request = UNNotificationRequest(identifier: "testNotification",
                                            content: notificationContent,
                                            trigger: trigger)
        
        userNotificationCenter.add(request) { (error) in
            if let error = error {
                print("Notification Error: ", error)
            }
        }
    }
}





