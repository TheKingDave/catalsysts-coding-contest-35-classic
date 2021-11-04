import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_ccc_helper/src/commands/init.dart';
import 'package:dart_ccc_helper/src/commands/run.dart';

typedef Program = String Function(String);

void cli(List<String> arguments, Program program) async {
  int? levels;
  final levelFile = File('.levels');
  if(await levelFile.exists()) {
    levels = int.tryParse(await levelFile.readAsString()) ?? 0;
  }

  CommandRunner('ccc', 'A helper script to run CCC competitions')
    ..addCommand(InitCommand())
    ..addCommand(RunCommand(program, levels))
    ..run(arguments);
}
