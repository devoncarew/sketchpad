import 'package:flutter/material.dart';

bool isLightColor(Color color) =>
    ThemeData.estimateBrightnessForColor(color) == Brightness.light;
