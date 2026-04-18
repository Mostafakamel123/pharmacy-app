// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final Color color;
  final Size dotSize;
  final double spacing;

  const TypingIndicator({
    Key? key,
    this.color = const Color(0xFF0EA5E9),
    this.dotSize = const Size(8, 8),
    this.spacing = 4,
  }) : super(key: key);

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations = _controllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;

      return Tween<double>(begin: 0, end: -8).animate(
        CurvedAnimation(
          parent: controller,
          curve: Interval(
            index * 0.15,
            0.5 + index * 0.15,
            curve: Curves.easeInOut,
          ),
        ),
      );
    }).toList();

    for (var controller in _controllers) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.dotSize.height + 16,
      width: widget.dotSize.width * 3 + widget.spacing * 2 + 16,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF374151)
              : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (index) => Transform.translate(
              offset: Offset(0, _animations[index].value),
              child: Container(
                width: widget.dotSize.width,
                height: widget.dotSize.height,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(widget.dotSize.width / 2),
                ),
                margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnlineIndicator extends StatelessWidget {
  final bool isOnline;
  final double size;

  const OnlineIndicator({
    Key? key,
    required this.isOnline,
    this.size = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
    );
  }
}

class ReadReceiptIndicator extends StatelessWidget {
  final String status;

  const ReadReceiptIndicator({
    Key? key,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final theme = Theme.of(context);

    return Tooltip(
      message: status,
      child: Icon(
        _getIcon(),
        size: 14,
        color: _getColor(),
      ),
    );
  }

  IconData _getIcon() {
    switch (status) {
      case 'sending':
        return Icons.schedule;
      case 'sent':
        return Icons.done;
      case 'delivered':
      case 'read':
        return Icons.done_all;
      default:
        return Icons.done;
    }
  }

  Color _getColor() {
    switch (status) {
      case 'read':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}
