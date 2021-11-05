import 'package:dart_ccc_helper/dart_ccc_helper.dart' as ccc;

void main(List<String> arguments) {
  ccc.cli(arguments, (x) => Handle(x).run());
}

class Handle {
  final ccc.StrRead read;
  final write = ccc.StrWriter();
  final List<Token> tokens;
  final Iterator<Token> iter;

  Handle._(this.read, this.tokens, this.iter);

  factory Handle(String inp) {
    final read = ccc.StrRead(inp);
    final numStatements = read.readIntLine().first;
    final tokens = read
        .readRawList(numStatements)
        .expand((e) => e)
        .map((e) => Token.fromString(e))
        .toList();
    return Handle._(read, tokens, tokens.iterator);
  }

  String run() {
    final funcs = <Func>[];
    bool openFunction = false;

    final ifStack = <If>[];

    while (iter.moveNext()) {
      Token s = iter.current;
      Statement? add;
      final type = getTypeFromString(s.content);
      switch (type) {
        case WordType.tStart:
          {
            funcs.add(Func());
            openFunction = true;
          }
          break;
        case WordType.tEnd:
          {
            if (ifStack.isEmpty) {
              openFunction = false;
            } else {
              if (!ifStack.last.handelingTrue) {
                funcs.last.addStatement(ifStack.removeLast());
              } else {
                ifStack.last.handelingTrue = false;
                iter.moveNext();
                assert(iter.current.content == 'else', 'If else not complete');
              }
            }
          }
          break;
        case WordType.tPrint:
          if (!openFunction) throw Exception('No open function! $s');
          iter.moveNext();
          add = Statement(type, iter.current);
          break;
        case WordType.tIf:
          iter.moveNext();
          ifStack.add(If(iter.current.content));
          break;
        case WordType.tElse:
          throw Exception('Should never occour');
        case WordType.tReturn:
          if (!openFunction) throw Exception('No open function! $s');
          iter.moveNext();
          add = Statement(type, iter.current);
          break;
      }

      if (add != null) {
        if (ifStack.isNotEmpty) {
          ifStack.last.addStatement(add);
        } else {
          if (!openFunction) {
            throw Exception('No open function');
          }
          funcs.last.addStatement(add);
        }
      }
    }

    write.write(funcs.map((e) => e.execute().print).join('\n'));

    return write.string;
  }
}

final boolMap = <String, bool>{
  'true': true,
  'false': false,
};

enum TokenType {
  word,
  string,
  int,
  bool,
}

class Token {
  final TokenType tokenType;
  dynamic content;

  Token(this.tokenType, this.content);

  factory Token.fromString(String str) {
    if (wordMap.containsKey(str)) {
      return Token(TokenType.word, str);
    } else if (int.tryParse(str) != null) {
      return Token(TokenType.int, int.parse(str));
    } else if (boolMap.containsKey(str)) {
      return Token(TokenType.bool, boolMap[str]);
    }
    return Token(TokenType.string, str);
  }
}

class If extends Statement {
  final bool input;
  final List<Statement> onTrue = [];
  final List<Statement> onFalse = [];
  bool handelingTrue = true;

  If(this.input) : super(WordType.tIf);

  void addStatement(Statement s) {
    (handelingTrue ? onTrue : onFalse).add(s);
  }

  @override
  ExecuteResult execute() {
    return Func(input ? onTrue : onFalse).execute();
  }
}

enum WordType {
  tStart,
  tEnd,
  tPrint,
  tIf,
  tElse,
  tReturn,
}

final wordMap = <String, WordType>{
  'start': WordType.tStart,
  'end': WordType.tEnd,
  'print': WordType.tPrint,
  'if': WordType.tIf,
  'else': WordType.tElse,
  'return': WordType.tReturn,
};

WordType getTypeFromString(String str) {
  return wordMap[str]!;
}

class Statement {
  final WordType type;
  final Token? extra;

  Statement(this.type, [this.extra]);

  ExecuteResult execute() {
    switch (type) {
      case WordType.tPrint:
        return ExecuteResult(extra!.content as String);
      case WordType.tReturn:
        return ExecuteResult('', true);
      default:
        throw Exception('The statement type $type is not executable');
    }
  }

  @override
  String toString() {
    return 'Statement{type: $type, extra: $extra}';
  }
}

class ExecuteResult {
  String print;
  dynamic value;
  bool returned;

  ExecuteResult(this.print, [this.returned=false, this.value]);
}

class Func {
  List<Statement> statements = [];

  Func([List<Statement>? statements]) {
    if(statements != null) {
      this.statements.addAll(statements);
    }
  }

  void addStatement(Statement s) {
    statements.add(s);
  }

  ExecuteResult execute() {
    String ret = '';
    for (final s in statements) {
      final res = s.execute();
      ret += res.print;
      if(res.returned) {
        return ExecuteResult(ret, true, res.value);
      }
    }
    return ExecuteResult(ret);
  }

  @override
  String toString() {
    return 'Function{statements: $statements}';
  }
}
