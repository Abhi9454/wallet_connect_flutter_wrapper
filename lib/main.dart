import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform = MethodChannel('samples.flutter.dev/walletConnect');

  String _batteryLevel = 'Unknown battery level.';
  String _accountId = 'No Account Id found.';

  Future<void> _getBatteryLevel() async {
    String batteryLevel;
    try {
      final int result = await platform.invokeMethod('connectToWallet');
      batteryLevel = 'Battery level at $result % .';
    } on PlatformException catch (e) {
      batteryLevel = "Failed to get battery level: '${e.message}'.";
    }

    setState(() {
      _batteryLevel = batteryLevel;
    });
  }

  Future<void> _getAccountId() async {
    String accountId;
    try {
      final String results = await platform.invokeMethod('getAccount');
      accountId = 'Account id is $results % .';
    } on PlatformException catch (e) {
      accountId = "Failed to get accounts id: '${e.message}'.";
    }

    setState(() {
      _accountId = accountId;
    });
  }

   @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              child: const Text('Connect to Wallet'),
              onPressed: _getBatteryLevel,
            ),
            ElevatedButton(
              child: const Text('Get Accounts'),
              onPressed: _getAccountId,
            ),
            Text(_accountId),
          ],
        ),
      ),
    );
  }
}
