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
                add = ifStack.removeLast();
              } else {
                ifStack.last.handelingTrue = false;
                iter.moveNext();
                assert(iter.current.content == 'else', 'If else not complete');
              }
            }
          }
          break;
        case WordType.tPrint:
          iter.moveNext();
          add = Statement(type, [iter.current]);
          break;
        case WordType.tIf:
          iter.moveNext();
          ifStack.add(If(iter.current));
          break;
        case WordType.tElse:
          throw Exception('Should never occour');
        case WordType.tReturn:
          iter.moveNext();
          add = Statement(type, [iter.current]);
          break;
        case WordType.tVar:
        case WordType.tSet:
          iter.moveNext();
          final name = iter.current;
          iter.moveNext();
          final content = iter.current;
          add = Statement(type, [name, content]);
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
    
    write.write(funcs.map((e) {
      final res = e.execute();
      if (res.error) return 'ERROR';
      return res.print;
    }).join('\n'));

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

  @override
  String toString() {
    return 'Token{tokenType: $tokenType, content: $content}';
  }
}

class If extends Statement {
  final Token input;
  final List<Statement> onTrue = [];
  final List<Statement> onFalse = [];
  bool handelingTrue = true;

  If(this.input) : super(WordType.tIf);

  void addStatement(Statement s) {
    (handelingTrue ? onTrue : onFalse).add(s);
  }

  @override
  ExecuteResult execute(Context context) {
    final inp = context.resolveVariable(input);
    if (inp.type != TokenType.bool) return ExecuteResult('', error: true);
    return Func(inp.content as bool ? onTrue : onFalse).execute(context);
  }

  @override
  String toString() {
    return 'If{input: $input}';
  }
}

enum WordType {
  tStart,
  tEnd,
  tPrint,
  tIf,
  tElse,
  tReturn,
  tVar,
  tSet,
}

final wordMap = <String, WordType>{
  'start': WordType.tStart,
  'end': WordType.tEnd,
  'print': WordType.tPrint,
  'if': WordType.tIf,
  'else': WordType.tElse,
  'return': WordType.tReturn,
  'var': WordType.tVar,
  'set': WordType.tSet,
};

WordType getTypeFromString(String str) {
  if (!wordMap.containsKey(str)) {
    throw Exception('Could not find type $str');
  }
  return wordMap[str.toLowerCase()]!;
}

class Statement {
  final WordType type;
  final List<Token> extras;

  Statement(this.type, [this.extras = const []]);

  ExecuteResult execute(Context context) {
    switch (type) {
      case WordType.tPrint:
        return ExecuteResult(
            '${context.resolveVariable(extras.first).content}');
      case WordType.tReturn:
        return ExecuteResult('', returned: true, value: extras);
      case WordType.tVar:
        if (context.variables.containsKey(extras.first.content)) {
          return ExecuteResult('', error: true);
        }
        final set = context.variables.containsKey(extras[1].content)
            ? context.variables[extras[1].content]!
            : Variable(extras[1].tokenType, extras[1].content);

        context.variables[extras.first.content] = set;
        
        return ExecuteResult('');
      case WordType.tSet:
        if (!context.variables.containsKey(extras.first.content)) {
          return ExecuteResult('', error: true);
        }
        final set = context.variables.containsKey(extras[1].content)
            ? context.variables[extras[1].content]!
            : Variable(extras[1].tokenType, extras[1].content);
        
        context.variables[extras.first.content] = set;
            
        return ExecuteResult('');
      default:
        throw Exception('The statement type $type is not executable');
    }
  }

  @override
  String toString() {
    return 'Statement{type: $type, extra: $extras}';
  }
}

class Variable {
  final TokenType type;
  final dynamic content;

  Variable(this.type, this.content);

  @override
  String toString() {
    return 'Variable{type: $type, content: $content}';
  }
}

class Context {
  final Map<String, Variable> variables = {};

  Variable resolveVariable(Token inp) {
    if (isVariable(inp)) {
      return getVariable(inp);
    }
    return Variable(inp.tokenType, inp.content);
  }

  bool isVariable(Token name) {
    return variables.containsKey(name.content);
  }

  Variable getVariable(Token name) {
    if (!isVariable(name)) {
      throw Exception('Could not find variable $name');
    }
    return variables[name.content]!;
  }
}

class ExecuteResult {
  String print;
  dynamic value;
  bool returned;
  bool error;

  ExecuteResult(this.print,
      {this.returned = false, this.value, this.error = false});
}

class Func {
  List<Statement> statements = [];

  Func([List<Statement>? statements]) {
    if (statements != null) {
      this.statements.addAll(statements);
    }
  }

  void addStatement(Statement s) {
    statements.add(s);
  }

  ExecuteResult execute([Context? context]) {
    context ??= Context();
    String ret = '';
    for (final s in statements) {
      final res = s.execute(context);
      if (res.error) {
        return ExecuteResult('', error: true);
      }
      ret += res.print;
      if (res.returned) {
        return ExecuteResult(ret, returned: true, value: res.value);
      }
    }
    return ExecuteResult(ret);
  }

  @override
  String toString() {
    return 'Function{statements: $statements}';
  }
}
