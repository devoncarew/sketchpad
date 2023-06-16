// ignore_for_file: avoid_print

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:sketchpad/services/dartservices.dart';
import 'package:split_view/split_view.dart';
import 'package:url_strategy/url_strategy.dart';

import 'console.dart';
import 'editor/editor.dart';
import 'execution/execution.dart';
import 'model.dart';
import 'problems.dart';
import 'theme.dart';
import 'widgets.dart';

// todo: deploy to firebase

// todo: have cmd-s re-run

// todo: improve the splitter control

// todo: show formatting status in the editor

// todo: show compiling and running status in the app view

// todo: combine the app and console views

// todo: window.flutterConfiguration

// todo: progress API

final ValueNotifier<bool> darkTheme = ValueNotifier(true);

const defaultGripSize = denseSpacing;

const appName = 'SketchPad';

const initialSource = '''
void main() {
  print('hello!');
  print('');

  for (int i = 0; i < 201; i++) {
    print(i);
  }

  print('');
  print('hello!');
}
''';

void main() {
  setPathUrlStrategy();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  _MyAppState();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: darkTheme,
      builder: (BuildContext context, bool value, _) {
        return MaterialApp(
          title: appName,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSwatch(
              brightness: value ? Brightness.dark : Brightness.light,
            ),
          ),
          home: const MyHomePage(title: appName),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final SplitViewController mainSplitter =
      SplitViewController(weights: [0.52, 0.48]);
  final SplitViewController codeAnalysisSplitter =
      SplitViewController(weights: [0.77, 0.23]);
  final SplitViewController uiConsoleSplitter =
      SplitViewController(weights: [0.64, 0.36]);

  late AppModel appModel;
  late AppServices appServices;

  @override
  void initState() {
    super.initState();

    final services =
        DartservicesApi(Client(), rootUrl: 'https://stable.api.dartpad.dev/');

    appModel = AppModel(initialSource);
    appServices = AppServices(appModel, services);

    appServices.populateVersions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final buttonStyle =
        TextButton.styleFrom(foregroundColor: colorScheme.onPrimary);

    final scaffold = Scaffold(
      appBar: AppBar(
        // leading: ,
        title: Row(children: [
          Image.asset(
            'assets/dart_logo_128.png',
            width: 32,
          ),
          const SizedBox(width: denseSpacing),
          const Text(appName),
          const SizedBox(width: defaultSpacing),
          const Expanded(
            child: Center(
              child: Text('snowy-flash-5437'),
            ),
          ),
          const SizedBox(width: defaultSpacing),
        ]),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () => print('hello'),
            icon: const Icon(Icons.add_circle),
            label: const Text('New'),
            style: buttonStyle,
          ),
          const VerticalDivider(),
          TextButton.icon(
            onPressed: () => print('hello'),
            icon: const Icon(Icons.download),
            label: const Text('Install SDK'),
            style: buttonStyle,
          ),
          const VerticalDivider(),
          ValueListenableBuilder(
            valueListenable: darkTheme,
            builder: (context, value, _) {
              // todo: animate the icon changes
              return IconButton(
                iconSize: defaultIconSize,
                splashRadius: defaultSplashRadius,
                onPressed: () => darkTheme.value = !value,
                icon: value
                    ? const Icon(Icons.light_mode_outlined)
                    : const Icon(Icons.dark_mode_outlined),
              );
            },
          ),
          const SizedBox(width: denseSpacing),
          IconButton(
            iconSize: defaultIconSize,
            splashRadius: defaultSplashRadius,
            onPressed: () => print('hello'),
            icon: const Icon(Icons.more_vert),
          ),
          const SizedBox(width: denseSpacing),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: denseSpacing),
                child: SplitView(
                  viewMode: SplitViewMode.Horizontal,
                  gripColor: theme.scaffoldBackgroundColor,
                  gripColorActive: colorScheme.surface,
                  gripSize: defaultGripSize,
                  controller: mainSplitter,
                  children: [
                    // todo: override the default indicator widget
                    Padding(
                      padding: const EdgeInsets.only(left: denseSpacing),
                      // child: SplitView( // Column
                      //   viewMode: SplitViewMode.Vertical,
                      //   gripColor: theme.scaffoldBackgroundColor,
                      //   gripColorActive: colorScheme.surface,
                      //   gripSize: defaultGripSize,
                      //   controller: codeAnalysisSplitter,
                      //   children: [
                      child: Column(
                        children: [
                          Expanded(
                            child: SectionWidget(
                              title: 'Code',
                              actions: [
                                ValueListenableBuilder<List<AnalysisIssue>>(
                                  valueListenable: appModel.analysisIssues,
                                  builder: (context, issues, _) {
                                    return ProblemsCountWidget(issues: issues);
                                  },
                                ),
                                const SizedBox(width: denseSpacing),
                                // todo: divider color
                                const SizedBox(
                                  height: smallIconSize + 8,
                                  child: VerticalDivider(),
                                ),
                                const SizedBox(width: denseSpacing),
                                ValueListenableBuilder<bool>(
                                  valueListenable: appModel.formattingBusy,
                                  builder: (context, bool value, _) {
                                    return MiniIconButton(
                                      icon: Icons.format_align_left,
                                      onPressed:
                                          value ? null : _handleFormatting,
                                    );
                                  },
                                ),
                                const SizedBox(width: denseSpacing),
                                // todo: divider color
                                const SizedBox(
                                  height: smallIconSize + 8,
                                  child: VerticalDivider(),
                                ),
                                const SizedBox(width: denseSpacing),
                                ValueListenableBuilder<bool>(
                                  valueListenable: appModel.compilingBusy,
                                  builder: (context, bool value, _) {
                                    return MiniIconButton(
                                      icon: Icons.play_arrow,
                                      onPressed:
                                          value ? null : _handleCompiling,
                                    );
                                  },
                                ),
                              ],
                              child: EditorWidget(appModel: appModel),
                            ),
                          ),
                          ValueListenableBuilder<List<AnalysisIssue>>(
                            valueListenable: appModel.analysisIssues,
                            builder: (context, issues, _) {
                              return ProblemsWidget(problems: issues);
                            },
                          ),
                        ],
                      ),
                    ),
                    // ),
                    Padding(
                      padding: const EdgeInsets.only(right: denseSpacing),
                      child: SplitView(
                        viewMode: SplitViewMode.Vertical,
                        gripColor: theme.scaffoldBackgroundColor,
                        gripColorActive: colorScheme.surface,
                        gripSize: defaultGripSize,
                        controller: uiConsoleSplitter,
                        children: [
                          SectionWidget(
                            title: 'App',
                            actions: [
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable:
                                    appModel.consoleOutputController,
                                builder: (context, value, _) {
                                  return MiniIconButton(
                                    icon: Icons.playlist_remove,
                                    onPressed: value.text.isEmpty
                                        ? null
                                        : _clearConsole,
                                  );
                                },
                              ),
                              const SizedBox(
                                height: smallIconSize + 8,
                                child: VerticalDivider(),
                              ),
                              ValueListenableBuilder<bool>(
                                valueListenable: appModel.compilingBusy,
                                builder: (context, bool value, _) {
                                  return SizedBox.square(
                                    dimension: smallIconSize,
                                    child: value
                                        ? const CircularProgressIndicator()
                                        : const SizedBox.square(),
                                  );
                                },
                              ),
                              const SizedBox(width: denseSpacing),
                              ValueListenableBuilder<bool>(
                                valueListenable: appModel.compilingBusy,
                                builder: (context, bool value, _) {
                                  return AnimatedRotation(
                                    turns: value ? 8 : 0,
                                    duration: const Duration(seconds: 3),
                                    child: const Icon(
                                      CupertinoIcons.gear,
                                      size: smallIconSize,
                                    ),
                                  );
                                },
                              ),
                            ],
                            child: ExecutionWidget(
                              appServices: appServices,
                            ),
                          ),
                          SectionWidget(
                            title: 'Console',
                            child: ConsoleWidget(appModel: appModel),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const StatusLineWidget(),
        ],
      ),
    );

    return Provider<AppServices>.value(
      value: appServices,
      child: Provider<AppModel>.value(
        value: appModel,
        child: scaffold,
      ),
    );
  }

  Future<void> _handleFormatting() async {
    final value = appModel.sourceCodeController.text;
    var result = await appServices.format(SourceRequest(source: value));
    if (result.hasNewString()) {
      appModel.sourceCodeController.text = result.newString;
    }
  }

  Future<void> _handleCompiling() async {
    final value = appModel.sourceCodeController.text;

    try {
      final response = await appServices.compile(CompileRequest(source: value));
      _clearConsole();
      appServices.executeJavaScript(response.result);
    } catch (error) {
      var message = error is ApiRequestError ? error.message : '$error';
      // var snackBar = SnackBar(content: Text('Compilation error: $e'));
      // ScaffoldMessenger.of(context).showSnackBar(snackBar);
      _clearConsole();
      appModel.appendLineToConsole(message);
    }
  }

  void _clearConsole() {
    appModel.clearConsole();
  }
}

class StatusLineWidget extends StatelessWidget {
  const StatusLineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final darkTheme = colorScheme.brightness == Brightness.dark;
    final textColor = colorScheme.onPrimaryContainer;
    final textStyle = TextStyle(color: textColor);

    final appModel = Provider.of<AppModel>(context);

    return Container(
      decoration: BoxDecoration(
        color: darkTheme ? colorScheme.surface : colorScheme.primary,
        border: Border(top: Divider.createBorderSide(context, width: 1.0)),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: denseSpacing,
        horizontal: defaultSpacing,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(children: [
              MiniIconButton(
                icon: Icons.keyboard,
                onPressed: () => print('hello'),
                color: textColor,
              ),
              const Expanded(child: SizedBox(width: defaultSpacing)),
              ValueListenableBuilder(
                valueListenable: appModel.runtimeVersions,
                builder: (content, version, _) {
                  return Text(
                    version.sdkVersion.isEmpty
                        ? ''
                        : 'Dart ${version.sdkVersion}',
                    style: textStyle,
                  );
                },
              ),
            ]),
          ),
          Text(' • ', style: textStyle),
          Expanded(
            child: Row(children: [
              ValueListenableBuilder(
                valueListenable: appModel.runtimeVersions,
                builder: (content, version, _) {
                  return Text(
                    version.flutterVersion.isEmpty
                        ? ''
                        : 'Flutter ${version.flutterVersion}',
                    style: textStyle,
                  );
                },
              ),
              const Expanded(child: SizedBox(width: defaultSpacing)),
              Hyperlink(
                url: 'https://dart.dev/tools/dartpad/privacy',
                displayText: 'Privacy notice',
                style: textStyle,
              ),
              const SizedBox(width: defaultSpacing),
              Hyperlink(
                url: 'https://github.com/dart-lang/dart-pad/issues',
                displayText: 'Feedback',
                style: textStyle,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class SectionWidget extends StatelessWidget {
  static const insets = 6.0;

  final String title;
  final List<Widget> actions;
  final Widget child;

  const SectionWidget({
    required this.title,
    required this.child,
    this.actions = const [],
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(denseSpacing),
            decoration: BoxDecoration(
              border:
                  Border(bottom: Divider.createBorderSide(context, width: 1)),
            ),
            child: SizedBox(
              height: defaultIconSize,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: defaultSpacing),
                  ...actions
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(denseSpacing),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
