import 'package:flutter/widgets.dart';
import 'package:pxshe_app/_core/_bootstrap.dart';
import 'package:pxshe_app/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Bootstrap.init();
  runApp(const App());
}