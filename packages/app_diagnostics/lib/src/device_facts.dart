import 'dart:io';
import 'dart:ui' show Brightness;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/widgets.dart' show MediaQueryData, WidgetsBinding;

/// When the process started, stamped by `main()`.
///
/// The header's `ts` is when *recording* started, which says nothing about how
/// long the app had been up — and that is the difference between a screen a
/// second after launch and the same screen showing a list fetched four hours
/// ago, because a list cached by a provider lives as long as the run does.
/// "Have you tried restarting the app" stops being a question.
abstract final class AppStart {
  static DateTime? _at;
  static Stopwatch? _running;

  /// When `main` ran, or null before it has said so.
  static DateTime? get at => _at;

  static set at(DateTime? value) {
    _at = value;
    _running = value == null ? null : (newStopwatch()..start());
  }

  /// The elapsed clock, so a test can hand over one it controls: a real
  /// [Stopwatch] cannot be wound forward, and waiting for one is not a test.
  @visibleForTesting
  static Stopwatch Function() newStopwatch = Stopwatch.new;

  /// Seconds since [at] was stamped, off a monotonic clock rather than the
  /// wall one: an NTP correction or a user setting the clock forward would
  /// otherwise report an app opened a minute ago as having run for hours.
  static int? get uptimeSeconds => _running?.elapsed.inSeconds;
}

/// The device, the screen and the clock — everything that is true of the phone
/// rather than of the app, as flat scalars for the session header.
///
/// None of it identifies anybody: a make and model are shared by millions, and
/// the UTC offset is coarser than the locale already in the header. What they
/// buy is the follow-up question that otherwise always gets asked. In order of
/// how often that is:
///
/// * `device` / `sdk` — whether a background task survives is the OEM battery
///   manager's decision, so a reminder that never arrives is usually answered by
///   the make of the phone;
/// * `tz` — "the date is one day off" is a UTC offset until proven otherwise;
/// * `screen` / `text_scale` — a control pushed off the edge is a layout report
///   that is unreproducible without both;
/// * `emulator` — present only when true, and then it is the whole context.
///
/// Every step is guarded: a missing fact costs a line in the header, and a
/// recording must start whatever the platform channel says.
Future<Map<String, Object?>> deviceEnvironment() async => {
  'tz': _utcOffset(DateTime.now()),
  ..._screenFacts(),
  ...await _deviceFacts(),
  // Absent until `main` stamped the start, rather than a null nobody can read.
  'uptime_s': ?AppStart.uptimeSeconds,
};

/// `+02:00`, the notation a reader already knows from an ISO timestamp.
String _utcOffset(DateTime now) {
  final offset = now.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final minutes = offset.inMinutes.abs();
  final hh = '${minutes ~/ 60}'.padLeft(2, '0');
  final mm = '${minutes % 60}'.padLeft(2, '0');
  return '$sign$hh:$mm';
}

/// Size in logical pixels — what layout code actually works in — plus the
/// density it was scaled from. Text scale and dark mode appear only when they
/// are not the default, so a header stays short for the common case.
Map<String, Object?> _screenFacts() {
  try {
    // Through the binding rather than `PlatformDispatcher.instance`: it is the
    // same view in the app, and the one a test can resize. An isolate with no
    // binding has no view either, and lands in the catch below.
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view == null) return const {};
    final media = MediaQueryData.fromView(view);
    // `scale` is defined at a font size, so read the factor off one: a non-linear
    // scaler has no single multiplier, and this is the one that matters for body
    // text.
    final textScale = media.textScaler.scale(14) / 14;
    return {
      'screen':
          '${media.size.width.round()}x${media.size.height.round()}'
          '@${media.devicePixelRatio.toStringAsFixed(2)}',
      if ((textScale - 1).abs() > 0.01)
        'text_scale': double.parse(textScale.toStringAsFixed(2)),
      if (media.platformBrightness == Brightness.dark) 'dark': true,
    };
  } on Object {
    return const {};
  }
}

Future<Map<String, Object?>> _deviceFacts() async {
  if (!Platform.isAndroid) return const {};
  try {
    final info = await DeviceInfoPlugin().androidInfo;
    return {
      'device': '${info.manufacturer} ${info.model}',
      'sdk': info.version.sdkInt,
      if (!info.isPhysicalDevice) 'emulator': true,
    };
  } on Object {
    return const {};
  }
}
