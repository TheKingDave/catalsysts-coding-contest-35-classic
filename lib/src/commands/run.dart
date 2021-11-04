import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:chalk/chalk.dart';
import 'package:dart_ccc_helper/src/cli.dart';
import 'package:path/path.dart';

class RunCommand extends Command {
  final _ch = Chalk();
  final Program _program;
  final int? _levels;

  RunCommand(this._program, this._levels);

  @override
  String get description =>
      'Run the program against a specified level and input';

  @override
  String get name => 'run';

  @override
  void run() async {
    if (_levels == null) {
      throw Exception(_ch.red(
          'Project is not initialized, use "ccc init" to initialize the project'));
    }

    if (argResults!.rest.length != 2) {
      throw Exception(_ch.red('Usage: ccc run [level] [input]'));
    }

    final level = int.tryParse(argResults!.rest.first) ?? 0;
    if (level == 0 || level > _levels!) {
      throw Exception(
          _ch.red('Level not in range [0, $_levels] or not a number'));
    }

    final input = argResults!.rest[1];

    final fileList = <File>[];
    // level1_1.in
    if (input.toLowerCase() == 'all') {
      fileList.addAll(await Directory('!input/level$level')
          .list()
          .where((l) => l is File)
          .where((f) => basename(f.path).endsWith('.in'))
          .cast<File>()
          .toList());
    } else {
      fileList.add(File('!input/level$level/level${level}_$input.in'));
    }

    await Future.wait(fileList.map((file) async {
      if (!await file.exists()) {
        throw Exception(_ch.red('Could not find file ${file.path}'));
      }
    }));

    await Future.wait(fileList.map((file) async {
      final inputData = await file.readAsString();

      String output;
      try {
        output = _program(inputData);
      } on Exception {
        print(_ch.red(
            'Got error while executing file ${_ch.blue(basename(file.path))}'));
        rethrow;
      }

      final outputFile =
          '!output/level$level/${basename(file.path).replaceAll('.in', '.out')}';
      await File(outputFile).writeAsString(output);
      print(_ch.green('Executed for file: ') + _ch.blue(basename(file.path)));
    }));
  }
}
