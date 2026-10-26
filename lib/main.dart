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
  String? launchedBy;
  String? startupError;
  try {
    // If setting up notifications fails or hangs, still open the app and say why.
    launchedBy = await scheduler.init().timeout(const Duration(seconds: 8));
  } catch (e, stack) {
    startupError = '$e\n\n$stack';
    debugPrint('Start-up failed: $startupError');
  }
  runApp(CallAayaApp(launchCallerId: launchedBy, startupError: startupError));
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
  const CallAayaApp({super.key, this.launchCallerId, this.startupError});

  final String? launchCallerId;
  final String? startupError;

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
      home: startupError != null
          ? _StartupErrorScreen(error: startupError!)
          : launchCallerId == null
              ? const HomeScreen()
              : IncomingCallScreen(
                  caller: callerById(launchCallerId),
                  returnHome: true,
                ),
    );
  }
}

/// Shown instead of closing when start-up fails, so the problem can be reported.
class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Call Aaya')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Notifications could not be set up. Calls will only ring while the app is open.\n'
              'Please send a screenshot of this screen to the developer.',
            ),
            const SizedBox(height: 12),
            SelectableText(error, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              ),
              child: const Text('Continue anyway'),
            ),
          ],
        ),
      ),
    );
  }
}
