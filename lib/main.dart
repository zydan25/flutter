import 'package:flutter/material.dart';
import 'package:stac/stac.dart';

import 'runtime/stac_runtime.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Stac.initialize();
  runApp(const StacRuntimeApp());
}
