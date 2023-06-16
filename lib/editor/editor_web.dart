// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sketchpad/model.dart';
import 'package:codemirror/codemirror.dart';

import '../services/dartservices.dart';

// todo: support code completion

class EditorWidget extends StatefulWidget {
  final AppModel appModel;

  const EditorWidget({
    required this.appModel,
    super.key,
  });

  @override
  State<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends State<EditorWidget> {
  StreamSubscription? listener;
  CodeMirror? codeMirror;

  @override
  void initState() {
    super.initState();

    ui_web.platformViewRegistry.registerViewFactory('dartpad-editor',
        (int viewId) {
      final div = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%';

      codeMirror = CodeMirror.fromElement(div, options: <String, dynamic>{
        'mode': 'dart',
        'theme': 'monokai',
        'lineNumbers': true,
        'lineWrapping': true,
      });

      return div;
    });
  }

  void _platformViewCreated(int id) {
    codeMirror!.refresh();
    _updateCodemirrorFromModel();

    listener?.cancel();
    listener = codeMirror!.onChange.listen((event) {
      _updateModelFromCodemirror(codeMirror!.doc.getValue() ?? '');
    });

    final appModel = widget.appModel;

    appModel.sourceCodeController.addListener(_updateCodemirrorFromModel);
    appModel.analysisIssues
        .addListener(() => _updateIssues(appModel.analysisIssues.value));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    codeMirror?.setTheme(
        colorScheme.brightness == Brightness.dark ? 'monokai' : 'default');

    return HtmlElementView(
      viewType: 'dartpad-editor',
      onPlatformViewCreated: _platformViewCreated,
    );
  }

  @override
  void dispose() {
    super.dispose();

    listener?.cancel();
    widget.appModel.sourceCodeController
        .removeListener(_updateCodemirrorFromModel);
  }

  void _updateModelFromCodemirror(String value) {
    final model = widget.appModel;

    model.sourceCodeController.removeListener(_updateCodemirrorFromModel);
    widget.appModel.sourceCodeController.text = value;
    model.sourceCodeController.addListener(_updateCodemirrorFromModel);
  }

  void _updateCodemirrorFromModel() {
    var value = widget.appModel.sourceCodeController.text;
    codeMirror!.doc.setValue(value);
  }

  void _updateIssues(List<AnalysisIssue> issues) {
    final doc = codeMirror!.doc;

    for (final marker in doc.getAllMarks()) {
      marker.clear();
    }

    for (final issue in issues) {
      final line = math.max(issue.line - 1, 0);
      final column = math.max(issue.column - 1, 0);

      doc.markText(
        Position(line, column),
        Position(line, column + issue.charLength),
        className: 'squiggle-${issue.kind}',
        title: issue.message,
      );
    }
  }
}
