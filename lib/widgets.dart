import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url;

import 'theme.dart';
import 'utils.dart';

class Hyperlink extends StatefulWidget {
  final String url;
  final String? displayText;
  final TextStyle? style;

  const Hyperlink({
    required this.url,
    this.displayText,
    this.style,
    Key? key,
  }) : super(key: key);

  @override
  State<Hyperlink> createState() => _HyperlinkState();
}

class _HyperlinkState extends State<Hyperlink> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    const underline = TextStyle(decoration: TextDecoration.underline);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (event) {
        setState(() => hovered = true);
      },
      onExit: (event) {
        setState(() => hovered = false);
      },
      child: GestureDetector(
        onTap: () => url.launchUrl(Uri.parse(widget.url)),
        child: Text(
          widget.displayText ?? widget.url,
          style: hovered ? underline.merge(widget.style) : widget.style,
        ),
      ),
    );
  }
}

class MiniIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  const MiniIconButton({
    required this.icon,
    this.onPressed,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      iconSize: smallIconSize,
      splashRadius: defaultSplashRadius,
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.all(2),
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
      color: color,
    );
  }
}

class LabelWidget extends StatelessWidget {
  final String text;
  final Color? chipColor;

  const LabelWidget(
    this.text,
    this.chipColor, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: chipColor,
      shape: const StadiumBorder(),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.only(left: 6.0, right: 6.0, bottom: 2.0),
        child: Text(
          text,
          style: TextStyle(
            color: chipColor == null || isLightColor(chipColor!)
                ? Colors.grey.shade900
                : Colors.grey.shade100,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class ProgressWidget extends StatelessWidget {
  final Progress status;

  const ProgressWidget({
    required this.status,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MessageStatus>(
      valueListenable: status.state,
      builder: (context, status, _) {
        return AnimatedOpacity(
          opacity: status.state == MessageState.closing ? 0.0 : 1.0,
          duration: status.state == MessageState.showing
              ? Duration.zero
              : animationDelay,
          curve: animationCurve,
          child: Text(status.message, style: subtleText),
        );
      },
    );
  }
}

class CompilingStatusWidget extends StatefulWidget {
  final ValueListenable<bool> status;

  const CompilingStatusWidget({
    required this.status,
    super.key,
  });

  @override
  State<CompilingStatusWidget> createState() => _CompilingStatusWidgetState();
}

class _CompilingStatusWidgetState extends State<CompilingStatusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    widget.status.addListener(_statusListener);
  }

  void _statusListener() {
    final value = widget.status.value;

    if (value) {
      controller.repeat();
    } else {
      controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final darkMode = colorScheme.brightness == Brightness.dark;

    final gearIcon =
        Image.asset('assets/gear-96-${darkMode ? 'light' : 'dark'}.png');

    return ValueListenableBuilder<bool>(
      valueListenable: widget.status,
      builder: (context, bool value, _) {
        return AnimatedOpacity(
          opacity: value ? 0.8 : 0.2,
          duration: animationDelay,
          child: AnimatedBuilder(
            animation: controller,
            builder: (BuildContext context, Widget? child) {
              return Transform.rotate(
                angle: controller.value * 2 * math.pi,
                child: gearIcon,
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    widget.status.removeListener(_statusListener);

    controller.dispose();

    super.dispose();
  }
}
