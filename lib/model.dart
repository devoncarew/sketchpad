import 'dart:async';

import 'package:flutter/material.dart';

import 'gists.dart';
import 'services/dartservices.dart';
import 'utils.dart';

// TODO: make sure that calls have built-in timeouts (10s, 60s, ...)

abstract class ExecutionService {
  Future<void> execute(String javaScript);
  Stream<String> get onStdout;
  Future<void> tearDown();
}

class AppModel {
  final ValueNotifier<bool> appReady = ValueNotifier(false);

  final ValueNotifier<List<AnalysisIssue>> analysisIssues = ValueNotifier([]);

  final ValueNotifier<String> title = ValueNotifier('');

  final TextEditingController sourceCodeController = TextEditingController();
  final TextEditingController consoleOutputController = TextEditingController();

  final ValueNotifier<bool> formattingBusy = ValueNotifier(false);
  final ValueNotifier<bool> compilingBusy = ValueNotifier(false);

  final Progress editingStatus = Progress();
  final Progress executionStatus = Progress();

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

  Future<void> performInitialLoad({
    String? gistId,
    required String fallbackSnippet,
  }) async {
    if (gistId == null) {
      appModel.sourceCodeController.text = fallbackSnippet;
      appModel.appReady.value = true;
      return;
    }

    final gistLoader = GistLoader();
    final progress =
        appModel.editingStatus.showMessage(initialText: 'Loading…');
    try {
      final gist = await gistLoader.load(gistId);
      progress.close();

      var title = gist.description ?? '';
      appModel.title.value =
          title.length > 40 ? '${title.substring(0, 40)}…' : title;

      final source = gist.mainDartSource;
      if (source == null) {
        appModel.editingStatus.showToast('main.dart not found');
        appModel.sourceCodeController.text = fallbackSnippet;
      } else {
        appModel.sourceCodeController.text = source;
      }

      appModel.appReady.value = true;
    } catch (e) {
      appModel.editingStatus.showToast('Error loading gist');
      progress.close();

      appModel.appendLineToConsole('Error loading gist: $e');

      appModel.sourceCodeController.text = fallbackSnippet;
      appModel.appReady.value = true;
    } finally {
      gistLoader.dispose();
    }
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
      _updateEditorProblemsStatus();
      return null;
    }).onError((error, stackTrace) {
      var message = error is ApiRequestError ? error.message : '$error';
      appModel.analysisIssues.value = [
        AnalysisIssue(kind: 'error', message: message),
      ];
      _updateEditorProblemsStatus();
      return null;
    });
  }

  void _updateEditorProblemsStatus() {
    final issues = appModel.analysisIssues.value;
    final progress = appModel.editingStatus.getNamedMessage('problems');

    if (issues.isEmpty) {
      if (progress != null) {
        progress.close();
      }
    } else {
      final message = '${issues.length} ${pluralize('issue', issues.length)}';
      if (progress == null) {
        appModel.editingStatus
            .showMessage(initialText: message, name: 'problems');
      } else {
        progress.updateText(message);
      }
    }
  }
}

int _compareIssues(AnalysisIssue a, AnalysisIssue b) {
  var diff = a.severity - b.severity;
  if (diff != 0) return -diff;

  return a.charStart - b.charStart;
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
