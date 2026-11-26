import 'package:flutter/widgets.dart';

/// Invokes [onDispose] when this widget is unmounted from the widget tree.
///
/// Ideal for modal bottom sheets that allocate local [TextEditingController]s
/// inside a helper function: unlike `showModalBottomSheet(...).whenComplete`,
/// `State.dispose` executes only after the route's exit animation finishes,
/// preventing "TextEditingController was used after being disposed" crashes.
class DisposableScope extends StatefulWidget {
  const DisposableScope({
    super.key,
    required this.onDispose,
    required this.child,
  });

  final VoidCallback onDispose;
  final Widget child;

  @override
  State<DisposableScope> createState() => _DisposableScopeState();
}

class _DisposableScopeState extends State<DisposableScope> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
