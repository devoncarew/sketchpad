// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:sketchpad/model.dart';
import 'package:codemirror/codemirror.dart';

// todo: how to pass the codemirror instance?

// todo: show analysis issues

// todo: support code completion

CodeMirror? codeMirror;
late final html.DivElement div;

void initEditorWidget() {
  ui_web.platformViewRegistry.registerViewFactory('dartpad-editor',
      (int viewId) {
    div = html.DivElement()
      ..style.width = '100%'
      ..style.height = '100%';
    codeMirror = CodeMirror.fromElement(div, options: <String, dynamic>{
      'mode': 'dart',
      'theme': 'monokai',
      'lineNumbers': true,
      'lineWrapping': true,
    });
    codeMirror!.doc.setValue('''
void main() {
  print('hello');
}
''');

    return div;
  });
}

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

  @override
  void dispose() {
    super.dispose();

    listener?.cancel();
    widget.appModel.codeController.removeListener(_updateCM);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        codeMirror?.refresh();

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        codeMirror?.setTheme(
            colorScheme.brightness == Brightness.dark ? 'monokai' : 'default');

        return HtmlElementView(
          viewType: 'dartpad-editor',
          onPlatformViewCreated: (id) {
            codeMirror!.refresh();

            listener?.cancel();
            listener = codeMirror!.onChange.listen((event) {
              _updateModel(codeMirror!.doc.getValue() ?? '');
            });

            widget.appModel.codeController.addListener(_updateCM);
          },
        );
      },
    );
  }

  void _updateModel(String value) {
    final model = widget.appModel;

    model.codeController.removeListener(_updateCM);
    widget.appModel.codeController.text = value;
    model.codeController.addListener(_updateCM);
  }

  void _updateCM() {
    var value = widget.appModel.codeController.text;
    codeMirror!.doc.setValue(value);
  }
}
