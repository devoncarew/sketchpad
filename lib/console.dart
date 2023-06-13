import 'package:flutter/material.dart';
import 'package:sketchpad/model.dart';

class ConsoleWidget extends StatelessWidget {
  final AppModel appModel;

  const ConsoleWidget({
    required this.appModel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: appModel.consoleController,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      expands: true,
      decoration: null,
      style: theme.textTheme.bodyMedium,
      readOnly: true,
    );
  }
}
