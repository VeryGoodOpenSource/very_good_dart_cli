import 'dart:io';

import 'package:path/path.dart' as p;

final targetPath = p.join('brick', '__brick__');
final sourcePath = p.join('my_cli');

final copyrightHeader = '''
// Copyright (c) {{current_year}}, Very Good Ventures
// https://verygood.ventures
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.
''';

void main() async {
  // Remove Previously Generated Files
  final targetDir = Directory(targetPath);
  if (targetDir.existsSync()) {
    await targetDir.delete(recursive: true);
  }
  await Shell.mkdir(targetDir.path);

  // Copy Project Files
  await Shell.cp(sourcePath, targetPath);

  // Convert Values to Variables
  await Future.wait(
    Directory(targetPath)
        .listSync(recursive: true)
        .whereType<File>()
        .map((_) async {
      var file = _;

      try {
        if (p.extension(file.path) == '.dart') {
          final contents = await file.readAsString();
          file = await file.writeAsString('$copyrightHeader\n$contents');
        }

        final contents = await file.readAsString();
        file = await file.writeAsString(
          contents
              // project_name
              .replaceAll('my_cli', '{{project_name.snakeCase()}}')
              .replaceAll('my-cli', '{{project_name.paramCase()}}')
              .replaceAll('MyCLI', '{{project_name.pascalCase()}}')
              .replaceAll('myCLI', '{{project_name.camelCase()}}')
              .replaceAll('MY_CLI', '{{project_name.constantCase()}}')
              // executable_name
              .replaceAll('my_executable', '{{executable_name.snakeCase()}}')
              // description
              .replaceAll('A Very Good CLI application', '{{description}}')
          // year
          .replaceAll('2022', '{{current_year}}'),
        );

        final fileSegments = file.path.split('/').sublist(2);

        if (fileSegments
            .any((e) => e.contains('my_cli') || e.contains('my_executable'))) {
          final newPathSegment = fileSegments
              .join('/')
              .replaceAll(
                'my_cli',
                '{{project_name.snakeCase()}}',
              )
              .replaceAll(
                'my_executable',
                '{{executable_name.snakeCase()}}',
              );
          final newPath = p.join(targetPath, newPathSegment);
          File(newPath).createSync(recursive: true);
          file.renameSync(newPath);
        }
      } catch (_) {}
    }),
  );

  Directory(p.join(targetPath, 'my_cli')).deleteSync(recursive: true);
}

class Shell {
  static Future<void> cp(String source, String destination) {
    return _Cmd.run('cp', ['-rf', source, destination]);
  }

  static Future<void> rm(String source) {
    return _Cmd.run('rm', ['-rf', source]);
  }

  static Future<void> mkdir(String destination) {
    return _Cmd.run('mkdir', ['-p', destination]);
  }
}

class _Cmd {
  static Future<ProcessResult> run(
    String cmd,
    List<String> args, {
    bool throwOnError = true,
    String? processWorkingDir,
  }) async {
    final result = await Process.run(cmd, args,
        workingDirectory: processWorkingDir, runInShell: true);

    if (throwOnError) {
      _throwIfProcessFailed(result, cmd, args);
    }
    return result;
  }

  static void _throwIfProcessFailed(
    ProcessResult pr,
    String process,
    List<String> args,
  ) {
    if (pr.exitCode != 0) {
      final values = {
        'Standard out': pr.stdout.toString().trim(),
        'Standard error': pr.stderr.toString().trim()
      }..removeWhere((k, v) => v.isEmpty);

      String message;
      if (values.isEmpty) {
        message = 'Unknown error';
      } else if (values.length == 1) {
        message = values.values.single;
      } else {
        message = values.entries.map((e) => '${e.key}\n${e.value}').join('\n');
      }

      throw ProcessException(process, args, message, pr.exitCode);
    }
  }
}
