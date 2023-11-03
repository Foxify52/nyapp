import 'package:flutter/material.dart';

class AnimatedDialog extends StatefulWidget {
  final Widget child;

  const AnimatedDialog({super.key, required this.child});

  @override
  State<AnimatedDialog> createState() => AnimatedDialogState();

  static AnimatedDialogState? of(BuildContext context) {
    return context.findAncestorStateOfType<AnimatedDialogState>();
  }
}

class AnimatedDialogState extends State<AnimatedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<Offset> offset;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    CurvedAnimation curvedAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.decelerate,
    );

    offset = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(curvedAnimation);

    controller.forward();
  }

  Future<void> slideOut() async {
    await controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: offset,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
