import 'package:flutter/material.dart';

import 'app.dart';
import 'core/logger/app_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  logger.i("ROS Mobile App Starting...");
  runApp(const ROSApp());
}
