import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../call_scheduler.dart';
import '../characters.dart';
import 'home_screen.dart';
import 'in_call_screen.dart';

/// True while a ringing screen is open, so the in-app timer and the
/// notification can't both open one at the same moment.
bool callScreenShowing = false;

/// The ringing screen. Looks like a real incoming call.
class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({super.key, required this.caller, this.returnHome = false});

  final Caller caller;

  /// True when the app was opened by the call itself, so there is no screen to go back to.
  final bool returnHome;

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> with SingleTickerProviderStateMixin {
  final _player = AudioPlayer();
  late final AnimationController _pulse;
  Timer? _vibrate;
  Timer? _giveUp;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    callScreenShowing = true;
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    CallScheduler.instance.cancel();
    _startRinging();
    // Like a real call, stop ringing after 45 seconds.
    _giveUp = Timer(const Duration(seconds: 45), _decline);
  }

  Future<void> _startRinging() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('ringtone.wav'));
    } catch (e) {
      debugPrint('Ringtone failed: $e');
    }
    _vibrate = Timer.periodic(const Duration(milliseconds: 1500), (_) => HapticFeedback.vibrate());
  }

  Future<void> _stopRinging() async {
    _vibrate?.cancel();
    _giveUp?.cancel();
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> _decline() async {
    if (_leaving) {
      return;
    }
    _leaving = true;
    await _stopRinging();
    if (!mounted) {
      return;
    }
    if (widget.returnHome || !Navigator.of(context).canPop()) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _accept() async {
    if (_leaving) {
      return;
    }
    _leaving = true;
    await _stopRinging();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => InCallScreen(caller: widget.caller, returnHome: widget.returnHome),
      ),
    );
  }

  @override
  void dispose() {
    callScreenShowing = false;
    _vibrate?.cancel();
    _giveUp?.cancel();
    _pulse.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.caller;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(c.color, Colors.black, 0.35)!, Colors.black],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 48),
                const Text('Incoming call', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  c.name,
                  style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text('Mobile', style: TextStyle(color: Colors.white60, fontSize: 15)),
                const Spacer(),
                ScaleTransition(
                  scale: Tween(begin: 0.92, end: 1.06).animate(
                    CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                  ),
                  child: CircleAvatar(
                    radius: 72,
                    backgroundColor: c.color,
                    child: Text(c.emoji, style: const TextStyle(fontSize: 72)),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 56),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _RoundAction(
                        color: const Color(0xFFE53935),
                        icon: Icons.call_end,
                        label: 'Decline',
                        onTap: _decline,
                      ),
                      _RoundAction(
                        color: const Color(0xFF43A047),
                        icon: Icons.call,
                        label: 'Accept',
                        onTap: _accept,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.color, required this.icon, required this.label, required this.onTap});

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 72,
              height: 72,
              child: Icon(icon, color: Colors.white, size: 34),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
