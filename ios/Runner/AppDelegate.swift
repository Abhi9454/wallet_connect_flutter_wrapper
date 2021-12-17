import UIKit
import Flutter
import Foundation
import WalletConnectSwift


protocol WalletConnectDelegate {
    func failedToConnect()
    func didConnect()
    func didDisconnect()
}

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate{
    
    
    var client: Client!
    var session: Session!
    var delegate: WalletConnectDelegate!

    let sessionKey = "sessionKey"
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    AppData.shared.requestNotificationAuthorization()
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let walletChannel = FlutterMethodChannel(name: "samples.flutter.dev/walletConnect",
                                              binaryMessenger: controller.binaryMessenger)
        walletChannel.setMethodCallHandler { [self](call: FlutterMethodCall, result: FlutterResult) -> Void in
            if (call.method == "connectToWallet") {
                 connect()
                }
            if (call.method == "getAccount"){
                getAccount()
            }
            if (call.method == "signMessage"){
                eth_sign()
            }
        }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func connectToWallet() -> String {
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

    func reconnectIfNeeded() {
        if let oldSessionObject = UserDefaults.standard.object(forKey: sessionKey) as? Data,
            let session = try? JSONDecoder().decode(Session.self, from: oldSessionObject) {
            client = Client(delegate: self, dAppInfo: session.dAppInfo)
            try? client.reconnect(to: session)
        }
    }

    // https://developer.apple.com/documentation/security/1399291-secrandomcopybytes
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

    
    func connect() {
        let connectionUrl = connectToWallet()
        //let deepLinkUrl = "https://metamask.app.link/wc?uri=\(connectionUrl)"
    
        
        if(AppData.shared.accounts.isEmpty){
            if let url = URL(string: connectionUrl), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.open(NSURL(string: "https://apps.apple.com/us/app/metamask-blockchain-wallet/id1438144202")! as URL)
            }
            reconnectIfNeeded()
        }       
    }
    
    func getAccount(result: FlutterResult){
        let accountId = AppData.shared.accounts;
        print(accountId)
        result(accountId)
    }
    
    func eth_sign() {
        try? client.eth_sign(url: session.url, account: session.walletInfo!.accounts[0], message: "0xdeadbeaf") {
                [weak self] response in
                self?.handleReponse(response, expecting: "Signature")
            }
    }
    
    private func handleReponse(_ response: Response, expecting: String) {
            if let error = response.error {
                print("Error \(error)")
                return
            }
            do {
                let result = try response.result(as: String.self)
                print("success and result is \(result)")
            } catch {
                print("Error catched")
            }
        }
}

extension AppDelegate : ClientDelegate {
    func client(_ client: Client, didFailToConnect url: WCURL) {
    }

    func client(_ client: Client, didConnect url: WCURL) {
        // do nothing
    }

    func client(_ client: Client, didConnect session: Session) {
        self.session = session
        AppData.shared.peerId = session.walletInfo?.peerId ?? ""
        AppData.shared.accounts = session.walletInfo?.accounts ?? []
        let sessionData = try! JSONEncoder().encode(session)
        UserDefaults.standard.set(sessionData, forKey: sessionKey)
        AppData.shared.sendNotification(title: "Successfully Connected", body : "Go back to Application")
    }

    func client(_ client: Client, didDisconnect session: Session) {
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    func client(_ client: Client, didUpdate session: Session) {
        AppData.shared.peerId = session.walletInfo?.peerId ?? ""
        AppData.shared.accounts = session.walletInfo?.accounts ?? []

    }
}


extension WCURL {
    var partiallyPercentEncodedStr: String {
        let params = "bridge=\(bridgeURL.absoluteString)&key=\(key)"
            .addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        return "wc:\(topic)@\(version)?\(params))"
    }

    var fullyPercentEncodedStr: String {
        absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
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




