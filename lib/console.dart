import 'package:flutter/material.dart';

import 'model.dart';
import 'theme.dart';

class ConsoleWidget extends StatefulWidget {
  final AppModel appModel;

  const ConsoleWidget({
    required this.appModel,
    super.key,
  });

  @override
  State<ConsoleWidget> createState() => _ConsoleWidgetState();
}

class _ConsoleWidgetState extends State<ConsoleWidget> {
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();

    scrollController = ScrollController();

    widget.appModel.consoleOutputController.addListener(_scrollToEnd);
  }

  @override
  void dispose() {
    widget.appModel.consoleOutputController.removeListener(_scrollToEnd);
    scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: widget.appModel.consoleOutputController,
      scrollController: scrollController,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      expands: true,
      decoration: null,
      style: theme.textTheme.bodyMedium,
      readOnly: true,
    );
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: animationDelay,
        curve: animationCurve,
      );
    });
  }
}
