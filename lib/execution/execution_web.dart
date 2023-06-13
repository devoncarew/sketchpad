// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

void initExecutionWidget() {
  ui_web.platformViewRegistry.registerViewFactory('dartpad-execution',
      (int viewId) {
    return html.IFrameElement()
      // todo:
      ..src = ''
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';
  });
}

class ExecutionWidget extends StatefulWidget {
  const ExecutionWidget({super.key});

  @override
  State<ExecutionWidget> createState() => _ExecutionWidgetState();
}

class _ExecutionWidgetState extends State<ExecutionWidget> {
  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: 'dartpad-execution');
  }
}
