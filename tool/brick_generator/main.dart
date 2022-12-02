import 'dart:io';

import 'package:path/path.dart' as p;

final targetPath = p.join('brick', '__brick__');
final sourcePath = p.join('src');

void main() async {
  // Remove Previously Generated Files
  final targetDir = Directory(targetPath);
  if (targetDir.existsSync()) {
    await targetDir.delete(recursive: true);
  }

  // Copy Project Files
  await Shell.cp(sourcePath, targetPath);

  // Convert Values to Variables
  await Future.wait(
    Directory(p.join(targetPath, 'my_cli'))
        .listSync(recursive: true)
        .whereType<File>()
        .map((_) async {
      var file = _;

      try {
        if (p.basename(file.path) == 'LICENSE') {
          await file.delete(recursive: true);
          return;
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
              .replaceAll('A Very Good CLI application', '{{description}}'),
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
  await Directory(p.join(targetPath, 'my_cli')).delete(recursive: true);
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
