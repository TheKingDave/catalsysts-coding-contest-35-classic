import 'package:dart_ccc_helper/dart_ccc_helper.dart' as ccc;

void main(List<String> arguments) {
  ccc.cli(arguments, (x) => "Executed:\n" + x);
}
