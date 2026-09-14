import 'package:package_info_plus/package_info_plus.dart';

/// The running build as `version+buildNumber` — the spelling a report quotes
/// back, and that somebody then has to match against a build. One spelling
/// matters more than the duplicated lines: a second site formatting it as
/// `version (buildNumber)` would be a second thing to recognise.
///
/// `PackageInfo.fromPlatform` caches the *value* statically, so the channel is
/// crossed once per process however often this is called — but it is an `async`
/// function handing back a fresh future every time, which is why a widget still
/// must not call it from `build`.
Future<String> readAppVersion() async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version}+${info.buildNumber}';
}
