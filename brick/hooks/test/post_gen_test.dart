import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../post_gen.dart' as post_gen;

class _MockHookContext extends Mock implements HookContext {}

class _MockProcessResult extends Mock implements ProcessResult {}

void main() {
  group('post_gen', () {
    late HookContext context;
    late ProcessResult processResult;
    late List<Invocation> invocations;

    setUp(() {
      context = _MockHookContext();
      processResult = _MockProcessResult();
      invocations = [];
    });

    Future<ProcessResult> runProcess(
      String executable,
      List<String> arguments, {
      String? workingDirectory,
      bool runInShell = false,
    }) async {
      final positionalArguments = [executable, arguments];
      final namedArguments = {
        const Symbol('workingDirectory'): workingDirectory,
        const Symbol('runInShell'): runInShell,
      };
      final invocation = Invocation.method(
        const Symbol('runProcess'),
        positionalArguments,
        namedArguments,
      );
      invocations.add(invocation);

      return processResult;
    }

    test('fixes `directives_ordering` Dart linter rule', () async {
      await post_gen.run(context, runProcess: runProcess);

      expect(invocations, contains(_IsDartDirectiveOrderingFix()));
    });
  });
}

Matcher isDartDirectiveOrderingFix() {
  return _IsDartDirectiveOrderingFix();
}

class _IsDartDirectiveOrderingFix extends Matcher {
  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! Invocation) {
      return false;
    }

    final invocation = item;
    final executableName = invocation.positionalArguments[0] as String;
    final arguments = invocation.positionalArguments[1] as List<String>;
    final workingDirectory =
        invocation.namedArguments[const Symbol('workingDirectory')] as String?;

    return executableName == 'dart' &&
        arguments.contains('fix') &&
        arguments.contains(Directory.current.path) &&
        arguments.contains('--apply') &&
        arguments.contains('--code=directives_ordering') &&
        workingDirectory == null;
  }

  @override
  Description describe(Description description) {
    return description.add('is a Dart fix for directives_ordering');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    return mismatchDescription.add('is not a Dart fix for directives_ordering');
  }
}
