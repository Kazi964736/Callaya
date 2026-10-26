import 'dart:async';

import 'package:flutter/material.dart';

import '../call_scheduler.dart';
import '../characters.dart';
import 'incoming_call_screen.dart';

class _DelayOption {
  const _DelayOption(this.label, this.duration);
  final String label;
  final Duration duration;
}

const _delays = <_DelayOption>[
  _DelayOption('5 sec', Duration(seconds: 5)),
  _DelayOption('10 sec', Duration(seconds: 10)),
  _DelayOption('30 sec', Duration(seconds: 30)),
  _DelayOption('1 min', Duration(minutes: 1)),
  _DelayOption('5 min', Duration(minutes: 5)),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Caller _caller = callers.first;
  _DelayOption _delay = _delays[1];
  bool _askedPermissions = false;
  bool _scheduling = false;

  Timer? _foregroundTimer;
  DateTime? _ringsAt;
  Timer? _countdownTicker;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _foregroundTimer?.cancel();
    _countdownTicker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
  }

  Future<void> _schedule() async {
    setState(() => _scheduling = true);
    try {
      final scheduler = CallScheduler.instance;
      if (!_askedPermissions) {
        final allowed = await scheduler.requestPermissions();
        _askedPermissions = true;
        if (!allowed && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifications are off, so the call can only ring while the app is open.'),
            ),
          );
        }
      }
      final caller = _caller;
      await scheduler.schedule(caller, _delay.duration);

      // If the app is still open on screen when the time comes, show the call
      // directly instead of waiting for the notification.
      _foregroundTimer?.cancel();
      _foregroundTimer = Timer(_delay.duration, () async {
        if (!mounted || _lifecycle != AppLifecycleState.resumed) {
          return;
        }
        await scheduler.cancel();
        _clearCountdown();
        if (!mounted || callScreenShowing) {
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => IncomingCallScreen(caller: caller),
          ),
        );
      });

      _ringsAt = DateTime.now().add(_delay.duration);
      _countdownTicker?.cancel();
      _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) {
          return;
        }
        if (_ringsAt != null && DateTime.now().isAfter(_ringsAt!)) {
          _clearCountdown();
        } else {
          setState(() {});
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${caller.name} will call in ${_delay.label}. You can lock your phone.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not schedule the call: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _scheduling = false);
      }
    }
  }

  void _clearCountdown() {
    _countdownTicker?.cancel();
    _countdownTicker = null;
    if (mounted) {
      setState(() => _ringsAt = null);
    }
  }

  Future<void> _cancel() async {
    _foregroundTimer?.cancel();
    await CallScheduler.instance.cancel();
    _clearCountdown();
  }

  String get _countdownText {
    final at = _ringsAt;
    if (at == null) {
      return '';
    }
    final left = at.difference(DateTime.now());
    final seconds = left.inSeconds < 0 ? 0 : left.inSeconds;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return m > 0 ? '$m min ${s.toString().padLeft(2, '0')} sec' : '$s sec';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Aaya 📞'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text('Who should call you?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                for (final c in callers)
                  _CallerCard(
                    caller: c,
                    selected: c.id == _caller.id,
                    onTap: () => setState(() => _caller = c),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('When?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in _delays)
                  ChoiceChip(
                    label: Text(d.label),
                    selected: d == _delay,
                    onSelected: (_) => setState(() => _delay = d),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _scheduling ? null : _schedule,
                icon: _scheduling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.phone_callback),
                label: Text('Get a call from ${_caller.name}'),
              ),
            ),
            if (_ringsAt != null) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: Text(_caller.emoji, style: const TextStyle(fontSize: 28)),
                  title: Text('Ringing in $_countdownText'),
                  subtitle: const Text('Lock your phone or switch apps — it will still ring.'),
                  trailing: TextButton(onPressed: _cancel, child: const Text('Cancel')),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Just for fun. All callers are made-up characters.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CallerCard extends StatelessWidget {
  const _CallerCard({required this.caller, required this.selected, required this.onTap});

  final Caller caller;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? caller.color.withValues(alpha: 0.15) : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? caller.color : Colors.transparent, width: 2),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: caller.color,
                child: Text(caller.emoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(height: 8),
              Text(caller.name, style: theme.textTheme.titleSmall, textAlign: TextAlign.center),
              const SizedBox(height: 2),
              Text(
                caller.subtitle,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
