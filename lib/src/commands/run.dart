import 'package:args/command_runner.dart';
import 'package:dart_ccc_helper/src/cli.dart';

class RunCommand extends Command {
  Program _program;
  
  RunCommand(this._program);

  @override
  String get description => 'Run the program against a specified level and input';

  @override
  String get name => 'run';
  
}