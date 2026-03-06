// lib/theme/theme_extensions.dart

import 'package:flutter/material.dart';

extension ThemeX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get texts => Theme.of(this).textTheme;

  ThemeData get theme => Theme.of(this);
}
