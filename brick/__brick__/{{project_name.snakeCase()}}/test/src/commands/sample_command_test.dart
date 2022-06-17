// Copyright (c) {{current_year}}, Very Good Ventures
// https://verygood.ventures
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:{{project_name.snakeCase()}}/src/command_runner.dart';
import 'package:{{project_name.snakeCase()}}/src/commands/commands.dart';
import 'package:{{project_name.snakeCase()}}/src/version.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class MockPubUpdater extends Mock implements PubUpdater {}

void main() {
  group('sample', () {
    late PubUpdater pubUpdater;
    late Logger logger;
    late {{project_name.pascalCase()}}CommandRunner commandRunner;

    setUp(() {
      pubUpdater = MockPubUpdater();

      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);

      logger = MockLogger();
      commandRunner = {{project_name.pascalCase()}}CommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      );
    });

    test('can be instantiated without explicit logger', () {
      final command = SampleCommand();
      expect(command, isNotNull);
    });

    test('tells a joke', () async {
      final exitCode = await commandRunner.run(['sample']);

      expect(exitCode, ExitCode.success.code);

      verify(
        () => logger.info('Which unicorn has a cold? The Achoo-nicorn!'),
      ).called(1);
    });
    test('tells a joke in cyan', () async {
      final exitCode = await commandRunner.run(['sample', '-c']);

      expect(exitCode, ExitCode.success.code);

      verify(
        () => logger.info(
          lightCyan.wrap('Which unicorn has a cold? The Achoo-nicorn!'),
        ),
      ).called(1);
    });

    test('wrong usage', () async {
      final exitCode = await commandRunner.run(['sample', '-p']);

      expect(exitCode, ExitCode.usage.code);

      verify(() => logger.err('Could not find an option or flag "-p".'))
          .called(1);
      verify(
        () => logger.info(
          '''
Usage: {{executable_name.snakeCase()}} sample [arguments]
-h, --help    Print this usage information.
-c, --cyan    Prints the same joke, but in cyan

Run "{{executable_name.snakeCase()}} help" to see global options.''',
        ),
      ).called(1);
    });
  });
}
