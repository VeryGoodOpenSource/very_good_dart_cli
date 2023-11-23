import 'dart:io';

import 'package:mason/mason.dart';
import 'package:meta/meta.dart';

/// Type definition for [Process.run].
typedef RunProcess = Future<ProcessResult> Function(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  bool runInShell,
});

Future<void> run(HookContext context,
// We intentionally ignore the trailing comma until the following mason issue is
// fixed: https://github.com/felangel/mason/pull/1164
// ignore: require_trailing_commas
    {@visibleForTesting RunProcess runProcess = Process.run}) async {
  // Some imports are relative to the user specified package name, hence
  // we try to fix the import directive ordering after the template has
  // been generated.
  //
  // We only fix for the [directives_ordering](https://dart.dev/tools/linter-rules/directives_ordering)
  // linter rules, as the other rule should be tackled by the template itself.
  await runProcess('dart', [
    'fix',
    Directory.current.path,
    '--apply',
    '--code=directives_ordering',
  ]);
}
