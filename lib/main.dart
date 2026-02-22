import 'package:claudy/app/app.dart';
import 'package:claudy/app/bootstrap.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBootstrap.initialize();
  runApp(const App());
}
