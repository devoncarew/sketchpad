import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sketchpad/services/dartservices.dart';

class AppModel {
  final String initialText;

  AppModel(this.initialText);

  TextEditingController get codeController =>
      _codeController ?? _initCodeController();

  TextEditingController? _codeController;

  TextEditingController _initCodeController() {
    _codeController = TextEditingController(text: initialText);
    return _codeController!;
  }

  late final TextEditingController consoleController = TextEditingController();

  final ValueNotifier<List<AnalysisIssue>> issues = ValueNotifier([]);

  final ValueNotifier<bool> formatting = ValueNotifier(false);
  final ValueNotifier<bool> compiling = ValueNotifier(false);

  final ValueNotifier<VersionResponse> version =
      ValueNotifier(VersionResponse());

  void appendToConsole(String str) {
    // todo: handle scrolling

    consoleController.text += str;
  }

  void clearConsole() => consoleController.clear();
}

class AppServices {
  final AppModel appModel;
  final DartservicesApi services;

  Timer? _debouncedNotifier;

  AppServices(this.appModel, this.services) {
    appModel.codeController.addListener(_handleCodeChanged);
  }

  void _handleCodeChanged() {
    _debouncedNotifier?.cancel();
    _debouncedNotifier = Timer(const Duration(milliseconds: 1000), () {
      _reAnalyze();
      _debouncedNotifier = null;
    });
  }

  void dispose() {
    // todo: call this

    appModel.codeController.removeListener(_handleCodeChanged);
  }

  Future<void> populateVersions() async {
    final version = await services.version();
    appModel.version.value = version;
  }

  Future<FormatResponse> format(SourceRequest request) async {
    try {
      appModel.formatting.value = true;
      return await services.format(request);
    } finally {
      appModel.formatting.value = false;
    }
  }

  Future<CompileResponse> compile(CompileRequest request) async {
    try {
      appModel.compiling.value = true;
      return await services.compile(request);
    } finally {
      appModel.compiling.value = false;
    }
  }

  void _reAnalyze() {
    var future =
        services.analyze(SourceRequest(source: appModel.codeController.text));
    future.then((AnalysisResults results) {
      appModel.issues.value = results.issues;
      return null;
    }).onError((error, stackTrace) {
      var message = error is ApiRequestError ? error.message : '$error';
      appModel.issues.value = [
        AnalysisIssue(kind: 'error', message: message),
      ];
      return null;
    });
  }
}
