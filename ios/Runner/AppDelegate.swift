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
    let batteryChannel = FlutterMethodChannel(name: "samples.flutter.dev/battery",
                                              binaryMessenger: controller.binaryMessenger)
        batteryChannel.setMethodCallHandler({ [self]
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      guard call.method == "getBatteryLevel" else {
        result(FlutterMethodNotImplemented)
        return
      }
        MainViewController().connect(result: result)
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

protocol WalletConnectDelegate {
    func failedToConnect()
    func didConnect()
    func didDisconnect()
}

class MainViewController: WalletConnectDelegate, ClientDelegate {
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
    
    func failedToConnect() {
        //
    }
    
    func didConnect() {
        print("connected")
    }
    
    func didDisconnect() {
        //
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


    func connect(result: FlutterResult) {
        let connectionUrl = connectWallet()
        //let deepLinkUrl = "https://metamask.app.link/wc?uri=\(connectionUrl)"
    

        if let url = URL(string: connectionUrl), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            print("error")
        }
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





