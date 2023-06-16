// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../model.dart';
import 'frame.dart';

// todo: register an execution service

class ExecutionWidget extends StatefulWidget {
  final AppServices appServices;

  const ExecutionWidget({
    required this.appServices,
    super.key,
  });

  @override
  State<ExecutionWidget> createState() => _ExecutionWidgetState();
}

class _ExecutionWidgetState extends State<ExecutionWidget> {
  ExecutionService? executionService;

  @override
  void initState() {
    super.initState();

    ui_web.platformViewRegistry.registerViewFactory('dartpad-execution',
        (int viewId) {
      // 'allow-popups' allows plugins like url_launcher to open popups.
      var frame = html.IFrameElement()
        ..sandbox!.add('allow-scripts')
        ..sandbox!.add('allow-popups')
        ..src = 'impl/frame.html'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';

      executionService = ExecutionServiceImpl(frame);

      return frame;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      viewType: 'dartpad-execution',
      onPlatformViewCreated: (int id) {
        widget.appServices.registerExecutionService(executionService!);
      },
    );
  }

  @override
  void dispose() {
    super.dispose();

    // Unregister the execution service.
    widget.appServices.registerExecutionService(null);
  }
}
