import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../characters.dart';
import 'home_screen.dart';

/// The answered call: a running timer while the character talks.
class InCallScreen extends StatefulWidget {
  const InCallScreen({super.key, required this.caller, this.returnHome = false});

  final Caller caller;
  final bool returnHome;

  @override
  State<InCallScreen> createState() => _InCallScreenState();
}

class _InCallScreenState extends State<InCallScreen> {
  final _tts = FlutterTts();
  final _started = DateTime.now();
  Timer? _clock;
  bool _ended = false;
  bool _muted = false;
  bool _speaker = true;
  String _status = 'Connecting…';

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
    _talk();
  }

  Future<void> _talk() async {
    final c = widget.caller;
    try {
      await _tts.awaitSpeakCompletion(true);
      final available = await _tts.isLanguageAvailable(c.language);
      // If this phone has no voice for the language, fall back to Indian English.
      await _tts.setLanguage(available == true ? c.language : 'en-IN');
      await _tts.setPitch(c.pitch);
      await _tts.setSpeechRate(c.rate);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) {
        setState(() => _status = '');
      }
      for (final line in c.lines) {
        if (_ended) {
          return;
        }
        if (!_muted) {
          await _tts.speak(line);
        }
        await Future<void>.delayed(const Duration(milliseconds: 700));
      }
      if (!_ended && mounted) {
        setState(() => _status = '${c.name} hung up');
        await Future<void>.delayed(const Duration(seconds: 2));
        _end();
      }
    } catch (e) {
      debugPrint('Voice failed: $e');
      if (mounted) {
        setState(() => _status = 'Voice not available on this phone');
      }
    }
  }

  Future<void> _end() async {
    if (_ended) {
      return;
    }
    _ended = true;
    _clock?.cancel();
    try {
      await _tts.stop();
    } catch (_) {}
    if (!mounted) {
      return;
    }
    if (widget.returnHome || !Navigator.of(context).canPop()) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      Navigator.of(context).pop();
    }
  }

  String get _elapsed {
    final s = DateTime.now().difference(_started).inSeconds;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _ended = true;
    _clock?.cancel();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.caller;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF111418),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 48),
              CircleAvatar(
                radius: 52,
                backgroundColor: c.color,
                child: Text(c.emoji, style: const TextStyle(fontSize: 52)),
              ),
              const SizedBox(height: 16),
              Text(
                c.name,
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                _status.isEmpty ? _elapsed : _status,
                style: const TextStyle(color: Colors.white60, fontSize: 16),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Toggle(
                    icon: _muted ? Icons.mic_off : Icons.mic,
                    label: 'Mute',
                    active: _muted,
                    onTap: () => setState(() => _muted = !_muted),
                  ),
                  const _Toggle(icon: Icons.dialpad, label: 'Keypad'),
                  _Toggle(
                    icon: Icons.volume_up,
                    label: 'Speaker',
                    active: _speaker,
                    onTap: () => setState(() => _speaker = !_speaker),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Material(
                color: const Color(0xFFE53935),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _end,
                  child: const SizedBox(
                    width: 72,
                    height: 72,
                    child: Icon(Icons.call_end, color: Colors.white, size: 34),
                  ),
                ),
              ),
              const SizedBox(height: 56),
            ],
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.icon, required this.label, this.active = false, this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: active ? Colors.white : Colors.white12,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 60,
              height: 60,
              child: Icon(icon, color: active ? Colors.black : Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
      ],
    );
  }
}
