import 'package:flutter/material.dart';

import '../model.dart';

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
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
