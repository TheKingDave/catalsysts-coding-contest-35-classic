import 'package:dart_ccc_helper/dart_ccc_helper.dart' as ccc;

void main(List<String> arguments) {
  ccc.cli(arguments, handle);
}

enum Type {
  start,
  end,
  print
}

Type getTypeFromString(String str) {
  switch(str.toLowerCase()) {
    case "start": return Type.start;
    case "end": return Type.end;
    case "print": return Type.print;
    default: throw Exception('Unknown type $str');
  }
}

class Statement {
  final Type type;
  final dynamic extra;

  Statement(this.type, [this.extra]);
  
  factory Statement.fromString(String str) {
    final split = str.split(' ');
    return Statement(getTypeFromString(split[0]), split.length == 2 ? split[1] : null);
  }

  String execute() {
    switch(type) {
      case Type.print: return extra as String;
      default: throw Exception('The statement type $type is not executable');
    }
  }
  
  @override
  String toString() {
    return 'Statement{type: $type, extra: $extra}';
  }
}

class Func {
  List<Statement> statements = [];
  
  void addStatement(Statement s) {
    statements.add(s);
  }
  
  String execute() {
    return statements.map((e) => e.execute()).join();
  }
  
  @override
  String toString() {
    return 'Function{statements: $statements}';
  }
}

String handle(String inp) {
  final read = ccc.StrRead(inp);
  final write = ccc.StrWriter();
  
  final numStatements = read.readIntLine().first;
  final stats = read.readRawList(numStatements).expand((e) => e).toList();
  
  
  final funcs = <Func>[];
  bool openFunction = false;
  
  final iter = stats.iterator;
  
  while(iter.moveNext()) {
    String s = iter.current;
    final type = getTypeFromString(s);
    switch(type) {
      case Type.start: {
        funcs.add(Func());
        openFunction = true;
      }
      break;
      case Type.end: openFunction = false;
      break;
      case Type.print: {
        if(!openFunction) throw Exception('No open function! $s');
        iter.moveNext();
        funcs.last.addStatement(Statement(type, iter.current));
      }
    }
  }
  
  write.write(funcs.map((e) => e.execute()).join('\n'));
  
  return write.string;
}
