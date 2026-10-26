import 'package:flutter/material.dart';

import 'call_scheduler.dart';
import 'characters.dart';
import 'screens/home_screen.dart';
import 'screens/incoming_call_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final scheduler = CallScheduler.instance;
  scheduler.onCallOpened = openIncomingCall;
  final launchedBy = await scheduler.init();
  runApp(CallAayaApp(launchCallerId: launchedBy));
}

/// Shows the ringing screen for [callerId] on top of whatever is open.
void openIncomingCall(String callerId) {
  final nav = navigatorKey.currentState;
  if (nav == null || callScreenShowing) {
    return;
  }
  nav.push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => IncomingCallScreen(caller: callerById(callerId)),
    ),
  );
}

class CallAayaApp extends StatelessWidget {
  const CallAayaApp({super.key, this.launchCallerId});

  final String? launchCallerId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Call Aaya',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE76F51)),
        useMaterial3: true,
      ),
      home: launchCallerId == null
          ? const HomeScreen()
          : IncomingCallScreen(
              caller: callerById(launchCallerId),
              returnHome: true,
            ),
    );
  }
}
