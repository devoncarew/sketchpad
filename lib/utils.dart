import 'package:flutter/material.dart';

bool isLightColor(Color color) =>
    ThemeData.estimateBrightnessForColor(color) == Brightness.light;

String pluralize(String word, int count) {
  return count == 1 ? word : '${word}s';
}
