import 'dart:convert';
import 'dart:io';

/// Loads a fixture from test/fixtures/ — the path is relative to the package
/// root, which is where `flutter test` runs from.
dynamic readFixture(String name) => jsonDecode(readFixtureString(name));

/// A fixture's raw contents, for the parsers that take text (WS frames, say).
String readFixtureString(String name) =>
    File('test/fixtures/$name').readAsStringSync();
