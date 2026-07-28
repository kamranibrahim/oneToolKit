import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widgets/tool_scaffold.dart';

class StopwatchTimerView extends StatefulWidget {
  const StopwatchTimerView({super.key});

  @override
  State<StopwatchTimerView> createState() => _StopwatchTimerViewState();
}

class _StopwatchTimerViewState extends State<StopwatchTimerView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Stopwatch
  final _sw = Stopwatch();
  Timer? _swTicker;
  final _laps = <Duration>[];

  // Countdown
  int _minutes = 5;
  int _seconds = 0;
  Duration _remaining = const Duration(minutes: 5);
  Timer? _cdTicker;
  bool _cdRunning = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _swTicker?.cancel();
    _cdTicker?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s.$ms';
    return '$m:$s.$ms';
  }

  String _fmtCd(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _swStartStop() {
    if (_sw.isRunning) {
      _sw.stop();
      _swTicker?.cancel();
    } else {
      _sw.start();
      _swTicker?.cancel();
      _swTicker = Timer.periodic(const Duration(milliseconds: 30), (_) {
        if (mounted) setState(() {});
      });
    }
    setState(() {});
  }

  void _swReset() {
    _sw
      ..stop()
      ..reset();
    _swTicker?.cancel();
    _laps.clear();
    setState(() {});
  }

  void _swLap() {
    if (!_sw.isRunning && _sw.elapsed == Duration.zero) return;
    setState(() => _laps.insert(0, _sw.elapsed));
  }

  void _cdApply() {
    _cdTicker?.cancel();
    _cdRunning = false;
    _remaining = Duration(minutes: _minutes, seconds: _seconds);
    setState(() {});
  }

  void _cdStartStop() {
    if (_cdRunning) {
      _cdTicker?.cancel();
      setState(() => _cdRunning = false);
      return;
    }
    if (_remaining <= Duration.zero) _cdApply();
    setState(() => _cdRunning = true);
    _cdTicker?.cancel();
    _cdTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= const Duration(seconds: 1)) {
        _cdTicker?.cancel();
        setState(() {
          _remaining = Duration.zero;
          _cdRunning = false;
        });
        HapticFeedback.heavyImpact();
        ToolScaffold.copy('', message: 'Timer finished');
        ToolScaffold.logAction(
          toolId: 'stopwatch_timer',
          toolName: 'Stopwatch & Timer',
          action: 'Timer finished',
        );
        return;
      }
      setState(() => _remaining -= const Duration(seconds: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'stopwatch_timer',
      title: 'Stopwatch & Timer',
      body: Column(
        children: [
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Stopwatch'),
              Tab(text: 'Timer'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(
                      child: Text(
                        _fmt(_sw.elapsed),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: _swStartStop,
                            child: Text(_sw.isRunning ? 'Pause' : 'Start'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _swLap,
                            child: const Text('Lap'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _swReset,
                            child: const Text('Reset'),
                          ),
                        ),
                      ],
                    ),
                    if (_laps.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Laps', style: theme.textTheme.titleSmall),
                      ..._laps.asMap().entries.map(
                            (e) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text('Lap ${_laps.length - e.key}'),
                              trailing: Text(_fmt(e.value)),
                            ),
                          ),
                    ],
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(
                      child: Text(
                        _fmtCd(_remaining),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Minutes $_minutes'),
                    Slider(
                      value: _minutes.toDouble(),
                      min: 0,
                      max: 120,
                      divisions: 120,
                      onChanged: _cdRunning
                          ? null
                          : (v) => setState(() {
                                _minutes = v.round();
                                _cdApply();
                              }),
                    ),
                    Text('Seconds $_seconds'),
                    Slider(
                      value: _seconds.toDouble(),
                      min: 0,
                      max: 59,
                      divisions: 59,
                      onChanged: _cdRunning
                          ? null
                          : (v) => setState(() {
                                _seconds = v.round();
                                _cdApply();
                              }),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: _remaining == Duration.zero && !_cdRunning
                                ? null
                                : _cdStartStop,
                            child: Text(_cdRunning ? 'Pause' : 'Start'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _cdRunning
                                ? null
                                : () {
                                    _minutes = 5;
                                    _seconds = 0;
                                    _cdApply();
                                  },
                            child: const Text('Reset 5:00'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
