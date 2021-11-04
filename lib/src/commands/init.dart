import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:chalk/chalk.dart';

class InitCommand extends Command {

  InitCommand() {
    argParser.addOption('levels', abbr: 'l', help: 'How many levers to generate', mandatory: true);
  }
  
  @override
  String get description => 'Initializes the folders and files for the competition';

  @override
  String get name => 'init';

  @override
  void run() async {
    final ch = Chalk();
    
    final levels = int.parse(argResults!['levels'] as String);

    print(ch.blue('Generating folders...'));
    
    await Directory('!description').create();
    await Directory('!input').create();
    await Directory('!output').create();
    
    for(int i = 1; i <= levels; i++) {
      await Directory('!input/level$i').create();
      await Directory('!output/level$i').create();
    }

    print(ch.green('Finished initializing'));
  }
}