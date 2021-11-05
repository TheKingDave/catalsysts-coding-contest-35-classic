import 'dart:collection';

import 'package:chalk/chalk.dart';

class StrRead with IterableMixin<String> implements Iterator<String> {
  final List<String> _lines;
  var _currentLine = -1;

  StrRead(String str)
      : _lines = str.split('\n').map((e) => e.trim()).toList(growable: false);

  @override
  get current => _lines[_currentLine];

  @override
  bool moveNext() {
    _currentLine++;
    return _lines.length > _currentLine;
  }

  @override
  Iterator<String> get iterator => this;

  String getNextLine() {
    if(!moveNext()) {
      throw Exception("Reached end of input");
    }
    return current;
  }

  /// Returns a list of space split variables of the line
  /// `2 3 4` => ['2', '3', '4']
  List<String> readLine() {
    return getNextLine().split(' ');
  }

  /// Returns a list of space split variables of the line and parses them to int
  /// `2 3 4` => [2, 3, 4]
  List<int> readIntLine() {
    return getNextLine().split(' ').map((e) => int.parse(e)).toList();
  }
  
  List<List<String>> readGrid(int height, int width) {
    final ret = <List<String>>[];
    for(int i = 0; i < height; i++) {
      final line = readLine();
      if(line.length != width) {
        throw Exception(Chalk().red('Line $i was not expected length $width but ${line.length}'));
      }
      ret.add(line);
    }
    return ret;
  }
  
  List<Map<String, String>> readList(int length, List<String> names) {
    final ret = <Map<String, String>>[];
    if(Set.from(names).length != names.length) {
      throw Exception(Chalk().red('All names must be unique'));
    }
    
    for(int i = 0; i < length; i++) {
      final line = readLine();
      if(line.length != names.length) {
        throw Exception(Chalk().red('Line $i was not expected length ${names.length} but ${line.length}'));
      }
      final map = <String, String>{};
      for(int j = 0; j < names.length; j++) {
        map[names[j]] = line[j];
      }
      ret.add(map);
    }
    return ret;
  }
  
  List<T> readObjectList<T>(int number, T Function(List<String> line) format) {
    final ret = <T>[];
    for(int i = 0; i < number; i++) {
      ret.add(format(readLine()));
    }
    return ret;
  }
  
}

class StrWriter {
  String string;

  StrWriter([this.string='']);
  
  void write(String line) {
    string += line + '\n';
  }
  
  void writeLine(Iterable<String> line) {
    write(line.join(' '));
  }

  void writeIntLine(Iterable<int> line) {
    write(line.join(' '));
  }
  
  void writeGrid(List<List<String>> grid) {
    for(final g in grid) {
      writeLine(g);
    }
  }
  
  void writeList(List<Map<String, String>> maps, List<String> names) {
    for(final m in maps) {
      writeLine(names.map((n) => m[n]!));
    }
  }

  void writeObjectList<T>(List<T> objects, dynamic Function(T object) format) {
    for(final o in objects) {
      final r = format(o);
      if(r is String) {
        write(r);
      } else if(r is List<String>) {
        writeLine(r);
      } else if(r is List<int>) {
        writeIntLine(r);
      } else {
        write(r.toString());
      }
    }
  }
  
}
