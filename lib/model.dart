import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sketchpad/services/dartservices.dart';

class AppModel {
  final String initialText;

  AppModel(this.initialText);

  TextEditingController get sourceCodeController =>
      _codeController ?? _initCodeController();

  TextEditingController? _codeController;

  TextEditingController _initCodeController() {
    _codeController = TextEditingController(text: initialText);
    return _codeController!;
  }

  late final TextEditingController consoleOutputController =
      TextEditingController();

  final ValueNotifier<List<AnalysisIssue>> analysisIssues = ValueNotifier([]);

  final ValueNotifier<bool> formattingBusy = ValueNotifier(false);
  final ValueNotifier<bool> compilingBusy = ValueNotifier(false);

  final ValueNotifier<VersionResponse> runtimeVersions =
      ValueNotifier(VersionResponse());

  void appendLineToConsole(String str) {
    consoleOutputController.text += '$str\n';
  }

  void clearConsole() => consoleOutputController.clear();
}

class AppServices {
  final AppModel appModel;
  final DartservicesApi services;

  ExecutionService? _executionService;
  StreamSubscription<String>? stdoutSub;

  Timer? reanalysisDebouncer;

  AppServices(this.appModel, this.services) {
    appModel.sourceCodeController.addListener(_handleCodeChanged);
  }

  void _handleCodeChanged() {
    reanalysisDebouncer?.cancel();
    reanalysisDebouncer = Timer(const Duration(milliseconds: 1000), () {
      _reAnalyze();
      reanalysisDebouncer = null;
    });
  }

  void dispose() {
    // todo: call this

    appModel.sourceCodeController.removeListener(_handleCodeChanged);
  }

  Future<void> populateVersions() async {
    final version = await services.version();
    appModel.runtimeVersions.value = version;
  }

  Future<FormatResponse> format(SourceRequest request) async {
    try {
      appModel.formattingBusy.value = true;
      return await services.format(request);
    } finally {
      appModel.formattingBusy.value = false;
    }
  }

  Future<CompileResponse> compile(CompileRequest request) async {
    try {
      appModel.compilingBusy.value = true;
      return await services.compile(request);
    } finally {
      appModel.compilingBusy.value = false;
    }
  }

  void registerExecutionService(ExecutionService? executionService) {
    // unreister the old
    stdoutSub?.cancel();

    // replace the service
    _executionService = executionService;

    // register the new
    if (_executionService != null) {
      stdoutSub = _executionService!.onStdout.listen((event) {
        appModel.appendLineToConsole(event);
      });
    }
  }

  void executeJavaScript(String javaScript) {
    _executionService?.execute(javaScript);
  }

  void _reAnalyze() {
    var future = services
        .analyze(SourceRequest(source: appModel.sourceCodeController.text));
    future.then((AnalysisResults results) {
      appModel.analysisIssues.value = results.issues.toList()
        ..sort(_compareIssues);
      return null;
    }).onError((error, stackTrace) {
      var message = error is ApiRequestError ? error.message : '$error';
      appModel.analysisIssues.value = [
        AnalysisIssue(kind: 'error', message: message),
      ];
      return null;
    });
  }
}

int _compareIssues(AnalysisIssue a, AnalysisIssue b) {
  var diff = a.severity - b.severity;
  if (diff != 0) return -diff;

  return a.charStart - b.charStart;
}

abstract class ExecutionService {
  Future<void> execute(String javaScript);
  Stream<String> get onStdout;
  Future<void> tearDown();
}

extension AnalysisIssueExtension on AnalysisIssue {
  int get severity {
    switch (kind) {
      case 'error':
        return 3;
      case 'warning':
        return 2;
      case 'info':
        return 1;
      default:
        return 0;
    }
  }
}
