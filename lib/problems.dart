import 'package:flutter/material.dart';

import 'services/dart_services.pb.dart';
import 'theme.dart';
import 'widgets.dart';

class ProblemsView extends StatelessWidget {
  final List<AnalysisIssue> problems;

  const ProblemsView({
    required this.problems,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView.builder(
      itemCount: problems.length,
      itemBuilder: (BuildContext context, int index) {
        final issue = problems[index];

        return Container(
          padding: const EdgeInsets.symmetric(vertical: denseSpacing / 2),
          color: (index % 2 == 0) ? null : colorScheme.surfaceVariant,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabelWidget(
                  issue.kind,
                  issue.colorFor(
                      darkMode: colorScheme.brightness == Brightness.dark)),
              const SizedBox(width: denseSpacing),
              Expanded(
                child: Text(
                  issue.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: denseSpacing),
              Text(
                'line ${issue.line}',
                maxLines: 1,
                overflow: TextOverflow.clip,
              )
            ],
          ),
        );
      },
    );
  }
}

extension AnalysisIssueExtension on AnalysisIssue {
  Color colorFor({bool darkMode = true}) {
    switch (kind) {
      case 'error':
        return darkMode ? Colors.red : Colors.red;
      case 'warning':
        return darkMode ? Colors.yellow : Colors.yellow;
      case 'info':
        return darkMode ? Colors.blue : Colors.blue.shade300;
      default:
        return darkMode ? Colors.grey : Colors.grey;
    }
  }
}
